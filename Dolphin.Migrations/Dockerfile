# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Step 1: Set working directory to /app (acts like solution root)
WORKDIR /src

# Step 2: Copy only source folders required for the API and its dependencies
COPY Dolphin.Migrations/ Dolphin.Migrations/
COPY Dolphin.Commands.Infrastructure/ Dolphin.Commands.Infrastructure/
COPY Dolphin.Domain/ Dolphin.Domain/
COPY Dolphin.Shared/ Dolphin.Shared/
COPY Dolphin.Protos/ Dolphin.Protos/

# Step 3: Restore dependencies
RUN dotnet restore Dolphin.Migrations/Dolphin.Migrations.csproj

# Step 4: Publish to a single folder
RUN dotnet publish Dolphin.Migrations/Dolphin.Migrations.csproj \
  -c Release \
  -o /src/publish \
  --no-restore \
  -p:PublishTrimmed=true \
  -p:PublishSingleFile=true \
  -p:DebugType=None \
  -p:DebugSymbols=false

# Final stage - runtime only
FROM mcr.microsoft.com/dotnet/runtime:8.0 AS final

WORKDIR /app

# Step 5: Copy published output
COPY --from=build /src/publish .

# Step 6: Set env variables
ENV DOTNET_RUNNING_IN_CONTAINER=true

# Step 7: Create non-root user
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# Step 8: Start the single-file executable
ENTRYPOINT ["./Dolphin.Migrations"]
