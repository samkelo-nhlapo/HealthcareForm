#!/usr/bin/env python3

from __future__ import annotations

import csv
import re
import subprocess
import sys
import tempfile
import unicodedata
import xml.etree.ElementTree as ET
from collections import defaultdict
from dataclasses import dataclass, field
from difflib import SequenceMatcher
from pathlib import Path


ROOT = Path("/home/samkelo/HealthcareForm")
DOWNLOADS = Path("/home/samkelo/Downloads")
BASE_CSV = DOWNLOADS / "deepseek_csv_20260404_9ec6cf.txt"
OUTPUT_CSV = ROOT / "generated" / "hospital_network_merged_20260404.csv"


PDF_SOURCES = [
    {
        "alias": "DBBS",
        "document": "DBBS-MG-2019-Network-Hospitals.pdf",
        "parser": "parse_dbbs_pdf",
    },
    {
        "alias": "TMED",
        "document": "TMED_Private_Hospital_Network_Prime_Plan_2025.pdf",
        "parser": "parse_tmed_pdf",
    },
    {
        "alias": "PnP",
        "document": "PnP_Primary_Hospital_Network_updated_Jan2025.pdf",
        "parser": "parse_pnp_pdf",
    },
    {
        "alias": "Old Mutual Health Solutions",
        "document": "Hospital_Network.pdf",
        "parser": "parse_old_mutual_pdf",
    },
    {
        "alias": "JHB Hospital List",
        "document": "JHB-Hosp-List.pdf",
        "parser": "parse_jhb_pdf",
    },
    {
        "alias": "GEMS GP 2026",
        "document": "Hospital Network GP.pdf",
        "parser": "parse_gems_gp_pdf",
    },
]


COUNTRIES = {"Namibia", "Botswana", "Lesotho"}
PROVINCE_CODES = {
    "EC": "Eastern Cape",
    "FS": "Free State",
    "GP": "Gauteng",
    "KZN": "KwaZulu-Natal",
    "LP": "Limpopo",
    "MP": "Mpumalanga",
    "NC": "Northern Cape",
    "NW": "North West",
    "WC": "Western Cape",
}
PROVINCE_NAMES = {
    "EASTERN CAPE": "Eastern Cape",
    "FREE STATE": "Free State",
    "GAUTENG": "Gauteng",
    "KWAZULU NATAL": "KwaZulu-Natal",
    "LIMPOPO": "Limpopo",
    "MPUMALANGA": "Mpumalanga",
    "NORTH WEST": "North West",
    "NORTHERN CAPE": "Northern Cape",
    "WESTERN CAPE": "Western Cape",
}
SOURCE_ORDER = {
    "EVO Network": 1,
    "DBBS": 2,
    "TMED": 3,
    "PnP": 4,
    "Accredited": 5,
    "Old Mutual Health Solutions": 6,
    "JHB Hospital List": 7,
    "GEMS GP 2026": 8,
}
BRAND_TOKENS = {
    "AKESO",
    "BUSAMED",
    "CLINIX",
    "INTERCARE",
    "LENMED",
    "LIFE",
    "MEDICLINIC",
    "MEDICROSS",
    "MELOMED",
    "NETCARE",
    "NURTURE",
    "NHN",
    "AFRICA",
    "AFRICAN",
    "HEALTHCARE",
    "HOSPITAL",
}
CORP_TOKENS = {"PTY", "LTD", "LIMITED", "INC", "CC", "PLC"}
GENERIC_TOKENS = {
    "AND",
    "CENTRE",
    "CENTER",
    "CLINIC",
    "DAY",
    "DENTAL",
    "HOSPITAL",
    "MEDICAL",
    "PRIVATE",
    "SUB",
    "ACUTE",
    "THE",
    "THEATRE",
    "THEATRES",
    "THEATER",
    "THEATERS",
}
MISSING_MARKERS = {"", "-", "N/A", "NULL"}


@dataclass
class SourceRecord:
    hospital_name: str
    town: str = ""
    province: str = ""
    country: str = "South Africa"
    group_operator: str = ""
    address: str = ""
    phone: str = ""
    sources: set[str] = field(default_factory=set)


@dataclass
class MasterRecord:
    hospital_name: str
    town: str
    province: str
    country: str
    group_operator: str
    address: str
    phone: str
    sources: set[str]
    from_base: bool = False


def clean_text(value: str | None) -> str:
    if value is None:
        return ""
    value = unicodedata.normalize("NFKC", value)
    value = value.replace("\xa0", " ").replace("’", "'").replace("–", "-").replace("—", "-")
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def clean_field(value: str | None) -> str:
    value = clean_text(value)
    return "" if value in MISSING_MARKERS else value


def title_if_upper(value: str) -> str:
    value = clean_text(value)
    if not value:
        return ""
    if any(ch.islower() for ch in value):
        return value
    value = value.title()
    value = value.replace("'S", "'s")
    value = re.sub(r"\bPty\b", "(Pty)", value)
    value = re.sub(r"\bLtd\b", "Ltd", value)
    value = value.replace("Mri", "MRI").replace("N1", "N1").replace("N17", "N17")
    return value


def normalize_operator(value: str) -> str:
    value = clean_field(value)
    if not value:
        return ""
    mapping = {
        "NHN": "NHN",
        "NATIONAL HOSPITAL NETWORK (NHN)": "NHN",
        "NATIONAL HOSPITAL NETWORK": "NHN",
        "LIFE HEALTHCARE": "Life Healthcare",
        "NETCARE": "Netcare",
        "MEDICLINIC": "Mediclinic",
        "LENMED": "Lenmed",
        "AKESO": "Akeso",
        "BUSAMED": "Busamed",
        "CLINIX": "Clinix",
        "MEDICROSS": "Medicross",
        "MELOMED": "Melomed",
        "INTERCARE": "Intercare",
        "OLD MUTUAL HEALTH SOLUTIONS": "Old Mutual Health Solutions",
    }
    upper = value.upper()
    if upper in mapping:
        return mapping[upper]
    return title_if_upper(value)


def infer_operator(name: str) -> str:
    name = clean_field(name)
    if not name:
        return ""
    patterns = [
        ("Netcare", r"\bNETCARE\b"),
        ("Life Healthcare", r"\bLIFE\b"),
        ("Mediclinic", r"\bMEDICLINIC\b"),
        ("Lenmed", r"\bLENMED\b"),
        ("Akeso", r"\bAKESO\b"),
        ("Clinix", r"\bCLINIX\b"),
        ("Medicross", r"\bMEDICROSS\b"),
        ("Melomed", r"\bMELOMED\b"),
        ("Busamed", r"\bBUSAMED\b"),
        ("Intercare", r"\bINTERCARE\b"),
        ("NHN", r"\bNHN\b"),
        ("Nurture", r"\bNURTURE\b"),
    ]
    upper = name.upper()
    for label, pattern in patterns:
        if re.search(pattern, upper):
            return label
    return ""


def normalize_phone(phone: str) -> str:
    phone = clean_field(phone)
    if not phone:
        return ""
    phone = re.sub(r"\s+", " ", phone)
    phone = phone.replace(" / ", "/")
    return phone


def split_location(value: str) -> tuple[str, str]:
    value = clean_field(value)
    if not value:
        return "", ""

    upper = normalize_name(value)
    for province_text, normalized in PROVINCE_NAMES.items():
        if upper.endswith(province_text):
            town = clean_field(value[: -len(province_text)])
            return town, normalized

    parts = upper.split()
    if parts:
        last = parts[-1]
        if last in PROVINCE_CODES:
            town = clean_field(value[: value.upper().rfind(last)])
            return town, PROVINCE_CODES[last]

    return clean_field(value), ""


def normalize_source_token(token: str) -> str:
    token = clean_text(token)
    if token == "EVO":
        return "EVO Network"
    return token


def normalize_source_set(tokens: set[str]) -> set[str]:
    return {normalize_source_token(token) for token in tokens if clean_text(token)}


def source_sort_key(token: str) -> tuple[int, str]:
    return (SOURCE_ORDER.get(token, 99), token)


def format_sources(tokens: set[str]) -> str:
    ordered = sorted(normalize_source_set(tokens), key=source_sort_key)
    return ", ".join(ordered)


def normalize_name(value: str) -> str:
    value = clean_field(value).upper()
    value = value.replace("MEDI-CLINIC", "MEDICLINIC")
    value = value.replace("MEDI CLINIC", "MEDICLINIC")
    value = value.replace("&", " AND ")
    value = value.replace("/", " ")
    value = value.replace("-", " ")
    value = re.sub(r"[^\w\s]", " ", value)
    value = re.sub(r"\bP[\.\s]*TY\b", " PTY ", value)
    value = re.sub(r"\bLTD\b", " LTD ", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def name_without_brand(value: str) -> str:
    tokens = [token for token in normalize_name(value).split() if token not in BRAND_TOKENS and token not in CORP_TOKENS]
    return " ".join(tokens)


def core_name(value: str) -> str:
    tokens = [
        token
        for token in normalize_name(value).split()
        if token not in BRAND_TOKENS and token not in CORP_TOKENS and token not in GENERIC_TOKENS
    ]
    return " ".join(tokens)


def similarity(a: str, b: str) -> float:
    return SequenceMatcher(None, a, b).ratio()


def load_pages(xml_path: Path) -> list[list[dict[str, int | str]]]:
    root = ET.parse(xml_path).getroot()
    pages: list[list[dict[str, int | str]]] = []
    for page in root.findall("page"):
        items: list[dict[str, int | str]] = []
        for text in page.findall("text"):
            content = clean_text("".join(text.itertext()))
            if not content:
                continue
            items.append(
                {
                    "top": int(text.attrib["top"]),
                    "left": int(text.attrib["left"]),
                    "width": int(text.attrib["width"]),
                    "text": content,
                }
            )
        pages.append(items)
    return pages


def render_pdf_to_xml(pdf_path: Path, work_dir: Path) -> Path:
    xml_path = work_dir / f"{pdf_path.stem}.xml"
    subprocess.run(
        ["pdftohtml", "-xml", "-hidden", "-nodrm", str(pdf_path), str(xml_path)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return xml_path


def cluster_rows(items: list[dict[str, int | str]], tolerance: int = 2) -> list[list[dict[str, int | str]]]:
    rows: list[list[dict[str, int | str]]] = []
    last_top: int | None = None
    for item in sorted(items, key=lambda entry: (int(entry["top"]), int(entry["left"]))):
        top = int(item["top"])
        if last_top is None or abs(top - last_top) > tolerance:
            rows.append([item])
            last_top = top
        else:
            rows[-1].append(item)
    return rows


def join_column(items: list[dict[str, int | str]]) -> str:
    return clean_text(" ".join(str(item["text"]) for item in sorted(items, key=lambda entry: int(entry["left"]))))


def parse_row_by_starts(items: list[dict[str, int | str]], starts: list[int]) -> list[str]:
    columns = [[] for _ in starts]
    starts_with_tail = starts + [10**9]
    for item in sorted(items, key=lambda entry: int(entry["left"])):
        left = int(item["left"])
        for index, start in enumerate(starts):
            if start <= left < starts_with_tail[index + 1]:
                columns[index].append(item)
                break
    return [join_column(column) for column in columns]


def tmed_page_starts(items: list[dict[str, int | str]]) -> list[int]:
    starts = sorted(
        {
            int(item["left"])
            for item in items
            if str(item["text"]).upper() == "HOSPITAL NAME"
            or str(item["text"]).upper() == "ADDRESS"
            or "CONTACT NUMBER" in str(item["text"]).upper()
        }
    )
    return starts if len(starts) >= 5 else [89, 387, 600, 812, 1025]


def parse_base_csv() -> list[MasterRecord]:
    records: list[MasterRecord] = []
    with BASE_CSV.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            province = clean_field(row.get("Province"))
            country = "South Africa"
            if province in COUNTRIES:
                country = province
                province = ""
            sources = set()
            for token in clean_field(row.get("Source")).split(","):
                token = normalize_source_token(token.strip())
                if token:
                    sources.add(token)
            records.append(
                MasterRecord(
                    hospital_name=clean_field(row.get("Hospital Name")),
                    town=clean_field(row.get("Town")),
                    province=province,
                    country=country,
                    group_operator=normalize_operator(clean_field(row.get("Group/Operator"))),
                    address=clean_field(row.get("Address")),
                    phone=normalize_phone(row.get("Phone", "")),
                    sources=sources,
                    from_base=True,
                )
            )
    return records


def parse_pnp_pdf(pdf_path: Path, alias: str, work_dir: Path) -> list[SourceRecord]:
    xml_path = render_pdf_to_xml(pdf_path, work_dir)
    pages = load_pages(xml_path)
    province = ""
    results: list[SourceRecord] = []
    for page in pages:
        for row in cluster_rows(page):
            text = join_column(row)
            if not text or text.startswith("Page "):
                continue
            if text.upper() in {
                "EASTERN CAPE",
                "FREE STATE",
                "GAUTENG",
                "KWAZULU-NATAL",
                "LIMPOPO",
                "MPUMALANGA",
                "NORTH WEST",
                "NORTHERN CAPE",
                "WESTERN CAPE",
                "NAMIBIA",
                "BOTSWANA",
                "LESOTHO",
            }:
                province = title_if_upper(text)
                continue
            if "HOSPITAL NAME" in text or "PRACTICE NUMBER" in text or "Updated January" in text:
                continue
            columns = parse_row_by_starts(row, [89, 207, 313, 579])
            if len(columns) != 4 or not columns[0] or not columns[2]:
                continue
            country = "South Africa"
            normalized_province = province
            if province in COUNTRIES:
                country = province
                normalized_province = ""
            results.append(
                SourceRecord(
                    hospital_name=title_if_upper(columns[2]),
                    town=title_if_upper(columns[0]),
                    province=normalized_province,
                    country=country,
                    group_operator=normalize_operator(columns[3]),
                    sources={alias},
                )
            )
    return results


def parse_tmed_pdf(pdf_path: Path, alias: str, work_dir: Path) -> list[SourceRecord]:
    xml_path = render_pdf_to_xml(pdf_path, work_dir)
    pages = load_pages(xml_path)
    province = ""
    results: list[SourceRecord] = []
    headings = {
        "EASTERN CAPE",
        "FREE STATE",
        "GAUTENG",
        "KWAZULU-NATAL",
        "LIMPOPO",
        "MPUMALANGA",
        "NORTH WEST",
        "NORTHERN CAPE",
        "WESTERN CAPE",
        "NAMIBIA",
        "BOTSWANA",
        "LESOTHO",
    }
    for page in pages:
        page_starts = tmed_page_starts(page)
        for row in cluster_rows(page):
            text = join_column(row)
            if not text or text.startswith("Page "):
                continue
            if text.upper() in headings:
                province = title_if_upper(text)
                continue
            if "HOSPITAL NAME" in text or "CONTACT NUMBER" in text or "TRANSMED PRIME PLAN" in text:
                continue
            columns = parse_row_by_starts(row, page_starts)
            if len(columns) != 5 or not columns[0]:
                continue
            country = "South Africa"
            normalized_province = province
            if province in COUNTRIES:
                country = province
                normalized_province = ""
            address_parts = [clean_field(columns[1]), clean_field(columns[2])]
            results.append(
                SourceRecord(
                    hospital_name=title_if_upper(columns[0]),
                    town=title_if_upper(columns[3]),
                    province=normalized_province,
                    country=country,
                    group_operator=infer_operator(columns[0]),
                    address=", ".join(part for part in address_parts if part),
                    phone=normalize_phone(columns[4]),
                    sources={alias},
                )
            )
    return results


def parse_dbbs_pdf(pdf_path: Path, alias: str, work_dir: Path) -> list[SourceRecord]:
    xml_path = render_pdf_to_xml(pdf_path, work_dir)
    pages = load_pages(xml_path)
    province = ""
    results: list[SourceRecord] = []
    headings = {
        "Western Cape",
        "Northern Cape",
        "Gauteng",
        "Eastern Cape",
        "KwaZulu-Natal",
        "Free State",
        "Mpumalanga",
        "Limpopo",
        "North West",
        "Namibia",
        "Botswana",
        "Lesotho",
    }
    for page in pages:
        for row in cluster_rows(page):
            text = join_column(row)
            if not text or "LIST OF NETWORK HOSPITALS" in text:
                continue
            if text in headings:
                province = text
                continue
            if "HOSPITAL NAME" in text or "PRACTICE NUMBER" in text:
                continue
            columns = parse_row_by_starts(row, [87, 300, 398, 665, 750])
            if len(columns) != 5 or not columns[0]:
                continue
            country = "South Africa"
            normalized_province = province
            if province in COUNTRIES:
                country = province
                normalized_province = ""
            results.append(
                SourceRecord(
                    hospital_name=title_if_upper(columns[0]),
                    town=title_if_upper(columns[1]),
                    province=normalized_province,
                    country=country,
                    group_operator=infer_operator(columns[0]),
                    address=clean_field(columns[2]),
                    phone=normalize_phone(columns[3]),
                    sources={alias},
                )
            )
    return results


def parse_old_mutual_pdf(pdf_path: Path, alias: str, work_dir: Path) -> list[SourceRecord]:
    xml_path = render_pdf_to_xml(pdf_path, work_dir)
    pages = load_pages(xml_path)
    results: list[SourceRecord] = []
    for page_number, page in enumerate(pages, start=1):
        if page_number < 3:
            continue
        for row in cluster_rows(page):
            text = join_column(row)
            if not text or text.startswith("PAGE "):
                continue
            if "Practice Number" in text or "Practice Name" in text or "Network Hospitals" in text:
                continue
            columns = parse_row_by_starts(row, [80, 134, 316, 457, 508, 669, 797, 893, 938, 1027, 1112])
            if len(columns) != 11 or not columns[0] or not columns[1]:
                continue
            description = clean_field(columns[2])
            town, province = split_location(clean_text(f"{columns[8]} {columns[9]}"))
            address_parts = [clean_field(columns[4]), clean_field(columns[5]), clean_field(columns[6]), clean_field(columns[7])]
            hospital_name = title_if_upper(columns[1])
            if not town or not province:
                continue
            if "PRIVATE HOSPITAL" not in description.upper():
                continue
            if "PRIVATE HOSPITALS" in hospital_name.upper() or hospital_name.upper().endswith("T/A"):
                continue
            results.append(
                SourceRecord(
                    hospital_name=hospital_name,
                    town=title_if_upper(town),
                    province=province,
                    country="South Africa",
                    group_operator=infer_operator(hospital_name),
                    address=", ".join(part for part in address_parts if part),
                    phone=normalize_phone(columns[10]),
                    sources={alias},
                )
            )
    return results


def parse_gems_gp_pdf(pdf_path: Path, alias: str, work_dir: Path) -> list[SourceRecord]:
    xml_path = render_pdf_to_xml(pdf_path, work_dir)
    pages = load_pages(xml_path)
    results: list[SourceRecord] = []
    for page in pages:
        for row in cluster_rows(page, tolerance=1):
            text = join_column(row)
            if not text or text.startswith("GEMS HOSPITAL NETWORK"):
                continue
            if "PROVINCE PHYSICAL TOWN" in text or "PRACTICE NAME" in text:
                continue
            columns = parse_row_by_starts(row, [190, 442, 642, 1456, 2056, 2200, 2526, 2704])
            if len(columns) != 8 or not columns[0] or not columns[3]:
                continue
            province_and_town = clean_field(columns[0])
            parts = province_and_town.split()
            if len(parts) < 2:
                continue
            province = title_if_upper(parts[0])
            town = title_if_upper(" ".join(parts[1:]))
            results.append(
                SourceRecord(
                    hospital_name=title_if_upper(columns[3]),
                    town=town,
                    province=province,
                    country="South Africa",
                    group_operator=infer_operator(columns[3]),
                    address=clean_field(columns[2]),
                    phone=normalize_phone(columns[7]),
                    sources={alias},
                )
            )
    return results


def parse_jhb_pdf(pdf_path: Path, alias: str, work_dir: Path) -> list[SourceRecord]:
    xml_path = render_pdf_to_xml(pdf_path, work_dir)
    pages = load_pages(xml_path)
    results: list[SourceRecord] = []
    for page in pages:
        starts = [
            item
            for item in page
            if int(item["left"]) <= 120
            and int(item["top"]) > 110
            and "HOSPITAL LIST" not in str(item["text"])
        ]
        starts = sorted(starts, key=lambda item: int(item["top"]))
        for index, start in enumerate(starts):
            start_top = int(start["top"])
            end_top = int(starts[index + 1]["top"]) - 1 if index + 1 < len(starts) else 10**9
            block = [item for item in page if start_top - 30 <= int(item["top"]) <= end_top]
            city_items = [
                item
                for item in block
                if 520 <= int(item["left"]) <= 610 and abs(int(item["top"]) - start_top) <= 2
            ]
            address_items = [item for item in block if 660 <= int(item["left"]) <= 900]
            phone_items = [item for item in block if int(item["left"]) >= 995]
            if not phone_items:
                continue
            address_rows = cluster_rows(address_items, tolerance=1)
            address = ", ".join(join_column(row) for row in address_rows if join_column(row))
            phones = []
            for row in cluster_rows(phone_items, tolerance=1):
                value = join_column(row)
                if value and value not in phones:
                    phones.append(value)
            results.append(
                SourceRecord(
                    hospital_name=title_if_upper(str(start["text"])),
                    town=title_if_upper(join_column(city_items)),
                    province="Gauteng",
                    country="South Africa",
                    group_operator=infer_operator(str(start["text"])),
                    address=address,
                    phone=normalize_phone(" / ".join(phones)),
                    sources={alias},
                )
            )
    return results


def build_indexes(records: list[MasterRecord]) -> dict[str, dict[str, list[int]]]:
    exact: defaultdict[str, list[int]] = defaultdict(list)
    brandless: defaultdict[str, list[int]] = defaultdict(list)
    core: defaultdict[str, list[int]] = defaultdict(list)
    for index, record in enumerate(records):
        exact[normalize_name(record.hospital_name)].append(index)
        brandless[name_without_brand(record.hospital_name)].append(index)
        core[core_name(record.hospital_name)].append(index)
    return {"exact": exact, "brandless": brandless, "core": core}


def choose_best_match(record: SourceRecord, candidates: list[int], master_records: list[MasterRecord]) -> int | None:
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]

    scored: list[tuple[float, int]] = []
    candidate_name = name_without_brand(record.hospital_name) or normalize_name(record.hospital_name)
    for index in candidates:
        master = master_records[index]
        score = 0.0
        if record.country == master.country:
            score += 0.2
        if record.province and record.province == master.province:
            score += 0.3
        if record.town and master.town and normalize_name(record.town) == normalize_name(master.town):
            score += 0.4
        master_name = name_without_brand(master.hospital_name) or normalize_name(master.hospital_name)
        score += similarity(candidate_name, master_name)
        scored.append((score, index))
    scored.sort(reverse=True)
    return scored[0][1]


def find_match(record: SourceRecord, master_records: list[MasterRecord], indexes: dict[str, dict[str, list[int]]]) -> int | None:
    exact_key = normalize_name(record.hospital_name)
    if exact_key in indexes["exact"]:
        return choose_best_match(record, indexes["exact"][exact_key], master_records)

    brandless_key = name_without_brand(record.hospital_name)
    if brandless_key and brandless_key in indexes["brandless"]:
        match = choose_best_match(record, indexes["brandless"][brandless_key], master_records)
        if match is not None:
            return match

    core_key = core_name(record.hospital_name)
    if core_key and core_key in indexes["core"]:
        match = choose_best_match(record, indexes["core"][core_key], master_records)
        if match is not None:
            return match

    best_index = None
    best_score = 0.0
    target = brandless_key or exact_key
    for index, master in enumerate(master_records):
        if record.country != master.country:
            continue
        master_key = name_without_brand(master.hospital_name) or normalize_name(master.hospital_name)
        score = similarity(target, master_key)
        if record.province and record.province == master.province:
            score += 0.1
        if record.town and master.town and normalize_name(record.town) == normalize_name(master.town):
            score += 0.1
        if score > best_score:
            best_score = score
            best_index = index
    if best_score >= 0.93:
        return best_index
    return None


def better_value(current: str, incoming: str) -> bool:
    current = clean_field(current)
    incoming = clean_field(incoming)
    if not incoming:
        return False
    if not current:
        return True
    if len(incoming) > len(current) and current in incoming:
        return True
    return False


def merge_record(record: SourceRecord, master_records: list[MasterRecord], indexes: dict[str, dict[str, list[int]]]) -> bool:
    match = find_match(record, master_records, indexes)
    if match is None:
        master_records.append(
            MasterRecord(
                hospital_name=record.hospital_name,
                town=record.town,
                province=record.province,
                country=record.country,
                group_operator=normalize_operator(record.group_operator or infer_operator(record.hospital_name)),
                address=record.address,
                phone=record.phone,
                sources=set(record.sources),
                from_base=False,
            )
        )
        new_index = len(master_records) - 1
        indexes["exact"][normalize_name(record.hospital_name)].append(new_index)
        indexes["brandless"][name_without_brand(record.hospital_name)].append(new_index)
        indexes["core"][core_name(record.hospital_name)].append(new_index)
        return True

    master = master_records[match]
    master.sources |= set(record.sources)
    if better_value(master.group_operator, record.group_operator):
        master.group_operator = normalize_operator(record.group_operator)
    elif not master.group_operator:
        master.group_operator = normalize_operator(infer_operator(master.hospital_name) or infer_operator(record.hospital_name))
    if better_value(master.address, record.address):
        master.address = clean_field(record.address)
    if better_value(master.phone, record.phone):
        master.phone = normalize_phone(record.phone)
    if better_value(master.town, record.town):
        master.town = clean_field(record.town)
    if better_value(master.province, record.province):
        master.province = clean_field(record.province)
    if not master.country and record.country:
        master.country = record.country
    return False


def sorted_records(records: list[MasterRecord]) -> list[MasterRecord]:
    return sorted(
        [record for record in records if should_keep_record(record)],
        key=lambda record: (
            record.country,
            record.province,
            record.town,
            normalize_name(record.hospital_name),
        ),
    )


def should_keep_record(record: MasterRecord) -> bool:
    if record.from_base:
        return True
    if not clean_field(record.town):
        return False
    upper_name = record.hospital_name.upper()
    if upper_name.startswith("-") or upper_name in PROVINCE_NAMES or upper_name in COUNTRIES:
        return False
    if upper_name in {"CENTRE", "TREATMENT)", "(OPHTHALMOLOGY ONLY)", "PRETORIA"}:
        return False
    return True


def write_output(records: list[MasterRecord]) -> None:
    OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "Hospital Name",
                "Town",
                "Province",
                "Country",
                "Group/Operator",
                "Address",
                "Phone",
                "Source",
            ],
            quoting=csv.QUOTE_MINIMAL,
        )
        writer.writeheader()
        for record in sorted_records(records):
            writer.writerow(
                {
                    "Hospital Name": record.hospital_name,
                    "Town": record.town,
                    "Province": record.province,
                    "Country": record.country or "South Africa",
                    "Group/Operator": record.group_operator,
                    "Address": record.address,
                    "Phone": record.phone,
                    "Source": format_sources(record.sources),
                }
            )


def count_rows(path: Path) -> int:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return sum(1 for _ in handle) - 1


def main() -> int:
    if not BASE_CSV.exists():
        print(f"Base CSV not found: {BASE_CSV}", file=sys.stderr)
        return 1

    master_records = parse_base_csv()
    indexes = build_indexes(master_records)
    additions_by_source: dict[str, int] = defaultdict(int)

    with tempfile.TemporaryDirectory(prefix="hospital_pdf_merge_") as temp_dir:
        work_dir = Path(temp_dir)
        for source in PDF_SOURCES:
            pdf_path = DOWNLOADS / source["document"]
            if not pdf_path.exists():
                print(f"Skipping missing PDF: {pdf_path}", file=sys.stderr)
                continue
            parser = globals()[source["parser"]]
            rows = parser(pdf_path, source["alias"], work_dir)
            for row in rows:
                added = merge_record(row, master_records, indexes)
                if added:
                    additions_by_source[source["alias"]] += 1

    write_output(master_records)

    print(f"Output: {OUTPUT_CSV}")
    print(f"Rows: {count_rows(OUTPUT_CSV)}")
    for alias in sorted(additions_by_source, key=source_sort_key):
        print(f"Added from {alias}: {additions_by_source[alias]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
