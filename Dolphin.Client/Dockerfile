# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Step 1: Set working directory to /app (acts like solution root)
WORKDIR /src

# Step 2: Copy only source folders required for the API and its dependencies
COPY Dolphin.Client/ Dolphin.Client/
COPY Dolphin.Shared/ Dolphin.Shared/
COPY Dolphin.Protos/ Dolphin.Protos/

# Step 3: Restore dependencies
RUN dotnet restore Dolphin.Client/Dolphin.Client.csproj

# Step 4: Publish to a single folder
RUN dotnet publish Dolphin.Client/Dolphin.Client.csproj \
  -c Release \
  -o /src/publish \
  --no-restore \
  -p:PublishTrimmed=true \
  -p:DebugType=None \
  -p:DebugSymbols=false

# Final stage - store the built output
FROM alpine:3.21 AS final

WORKDIR /app

# Step 5: Copy the built output
COPY --from=build /src/publish .