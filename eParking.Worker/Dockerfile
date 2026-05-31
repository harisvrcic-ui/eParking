FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY eParking.sln ./
COPY eParking.Worker/eParking.Worker.csproj eParking.Worker/
COPY eParking.Services/eParking.Services.csproj eParking.Services/
COPY eParking.Model/eParking.Model.csproj eParking.Model/

RUN dotnet restore eParking.Worker/eParking.Worker.csproj

COPY eParking.Worker/ eParking.Worker/
COPY eParking.Services/ eParking.Services/
COPY eParking.Model/ eParking.Model/

RUN dotnet publish eParking.Worker/eParking.Worker.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/runtime:9.0
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "eParking.Worker.dll"]
