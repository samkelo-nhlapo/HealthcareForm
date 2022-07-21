#Depending on the operating system of the host machines(s) that will build or run the containers, the image specified in the FROM statement may need to be changed.
#For more information, please see https://aka.ms/containercompat 

# production runtime
FROM mcr.microsoft.com/dotnet/framework/sdk:3.5 as build-av

WORKDIR . /app

#
COPY PatientEnrollmentVS.csproj ./
RUN ["dotnet", "restore"]
EXPOSE 80/tcp

# Copy everything else and build
COPY . /app
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/framework/aspnet:3.5
WORKDIR /app
COPY --from=build-av /app/out .
ENTRYPOINT ["dotnet", "PatientEnrollmentVS.dll"]