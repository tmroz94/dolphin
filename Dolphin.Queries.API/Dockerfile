# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Step 1: Set working directory to /app (acts like solution root)
WORKDIR /src

# Step 2: Copy only source folders required for the API and its dependencies
COPY Dolphin.Queries.API/ Dolphin.Queries.API/
COPY Dolphin.Queries.Application/ Dolphin.Queries.Application/
COPY Dolphin.Queries.Infrastructure/ Dolphin.Queries.Infrastructure/
COPY Dolphin.Shared/ Dolphin.Shared/
COPY Dolphin.Protos/ Dolphin.Protos/

# Step 3: Restore dependencies
RUN dotnet restore Dolphin.Queries.API/Dolphin.Queries.API.csproj

# Step 4: Publish to a single folder
RUN dotnet publish Dolphin.Queries.API/Dolphin.Queries.API.csproj \
  -c Release \
  -o /src/publish \
  --no-restore \
  -p:PublishTrimmed=true \
  -p:PublishSingleFile=true \
  -p:DebugType=None \
  -p:DebugSymbols=false

# Final stage - runtime only
FROM mcr.microsoft.com/dotnet/runtime:8.0 AS final

# Used to install curl for the healthcheck
USER root

# Step 5: Install curl for the healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Step 6: Copy published output
COPY --from=build /src/publish .

# Step 7: Set env variables
ENV DOTNET_RUNNING_IN_CONTAINER=true

# Step 8: Create non-root user
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# Step 9: Start the single-file executable
ENTRYPOINT ["./Dolphin.Queries.API"]
