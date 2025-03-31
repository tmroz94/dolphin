# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Step 1: Set working directory to /app (acts like solution root)
WORKDIR /src

# Step 2: Copy only source folders required for the API and its dependencies
COPY Dolphin.Commands.API/ Dolphin.Commands.API/
COPY Dolphin.Commands.Application/ Dolphin.Commands.Application/
COPY Dolphin.Commands.Infrastructure/ Dolphin.Commands.Infrastructure/
COPY Dolphin.Domain/ Dolphin.Domain/
COPY Dolphin.Shared/ Dolphin.Shared/
COPY Dolphin.Protos/ Dolphin.Protos/

# Step 3: Copy the local package and nuget.config
COPY ./.nugets/ /nugets

# Step 4: Add the local package source
RUN ["dotnet", "nuget", "add", "source", "/nugets", "-n", "LocalNugets"]

# Step 5: Restore dependencies
RUN dotnet restore Dolphin.Commands.API/Dolphin.Commands.API.csproj

# Step 6: Publish to a single folder
RUN dotnet publish Dolphin.Commands.API/Dolphin.Commands.API.csproj \
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

# Step 7: Install curl for the healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Step 8: Copy published output
COPY --from=build /src/publish .

# Step 9: Set env variables
ENV DOTNET_RUNNING_IN_CONTAINER=true

# Step 10: Create non-root user
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# Step 11: Start the single-file executable
ENTRYPOINT ["./Dolphin.Commands.API"]
