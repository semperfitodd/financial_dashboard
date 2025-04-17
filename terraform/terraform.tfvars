domain = "brewsentry.com"

dynamo_tables = {
  users = {
    attributes = [
      { name = "id", type = "S" },
      { name = "username", type = "S" },
      { name = "email", type = "S" }
    ]
    hash_key = "id"
    global_secondary_indexes = [
      {
        name            = "UsernameIndex"
        hash_key        = "username"
        projection_type = "ALL"
      },
      {
        name            = "EmailIndex"
        hash_key        = "email"
        projection_type = "ALL"
      }
    ]
  }

  insights = {
    attributes = [
      { name = "id", type = "S" },
      { name = "entityType", type = "S" },
      { name = "insightType", type = "S" },
      { name = "entity", type = "S" },
      { name = "date", type = "S" }
    ]
    hash_key = "id"
    global_secondary_indexes = [
      {
        name            = "EntityTypeIndex"
        hash_key        = "entityType"
        range_key       = "date"
        projection_type = "ALL"
      },
      {
        name            = "InsightTypeIndex"
        hash_key        = "insightType"
        range_key       = "date"
        projection_type = "ALL"
      },
      {
        name            = "EntityInsightTypeIndex"
        hash_key        = "entity"
        range_key       = "insightType"
        projection_type = "ALL"
      }
    ]
  }

  signals = {
    attributes = [
      { name = "id", type = "S" },
      { name = "entityType", type = "S" },
      { name = "signalType", type = "S" },
      { name = "entity", type = "S" },
      { name = "date", type = "S" }
    ]
    hash_key = "id"
    global_secondary_indexes = [
      {
        name            = "EntityTypeIndex"
        hash_key        = "entityType"
        range_key       = "date"
        projection_type = "ALL"
      },
      {
        name            = "SignalTypeIndex"
        hash_key        = "signalType"
        range_key       = "date"
        projection_type = "ALL"
      },
      {
        name            = "EntitySignalTypeIndex"
        hash_key        = "entity"
        range_key       = "signalType"
        projection_type = "ALL"
      }
    ]
  }

  forecasts = {
    attributes = [
      { name = "id", type = "S" },
      { name = "entityType", type = "S" },
      { name = "forecastType", type = "S" },
      { name = "entity", type = "S" },
      { name = "date", type = "S" },
      { name = "timeframe", type = "S" }
    ]
    hash_key = "id"
    global_secondary_indexes = [
      {
        name            = "EntityTypeIndex"
        hash_key        = "entityType"
        range_key       = "date"
        projection_type = "ALL"
      },
      {
        name            = "ForecastTypeIndex"
        hash_key        = "forecastType"
        range_key       = "date"
        projection_type = "ALL"
      },
      {
        name            = "EntityForecastTypeIndex"
        hash_key        = "entity"
        range_key       = "forecastType"
        projection_type = "ALL"
      },
      {
        name            = "TimeframeIndex"
        hash_key        = "timeframe"
        range_key       = "date"
        projection_type = "ALL"
      }
    ]
  }

  recommendations = {
    attributes = [
      { name = "id", type = "S" },
      { name = "entityType", type = "S" },
      { name = "recommendationType", type = "S" },
      { name = "entity", type = "S" },
      { name = "date", type = "S" },
      { name = "timeframe", type = "S" }
    ]
    hash_key = "id"
    global_secondary_indexes = [
      {
        name            = "EntityTypeIndex"
        hash_key        = "entityType"
        range_key       = "date"
        projection_type = "ALL"
      },
      {
        name            = "RecommendationTypeIndex"
        hash_key        = "recommendationType"
        range_key       = "date"
        projection_type = "ALL"
      },
      {
        name            = "EntityRecommendationTypeIndex"
        hash_key        = "entity"
        range_key       = "recommendationType"
        projection_type = "ALL"
      },
      {
        name            = "TimeframeIndex"
        hash_key        = "timeframe"
        range_key       = "date"
        projection_type = "ALL"
      }
    ]
  }

  filing_progress = {
    attributes = [
      { name = "cik", type = "S" },
      { name = "last_ingested_date", type = "S" }
    ]
    hash_key  = "cik"
    range_key = "last_ingested_date"
  }

  audit_log = {
    attributes = [
      { name = "id", type = "S" },
      { name = "timestamp", type = "S" },
      { name = "userId", type = "S" },
      { name = "action", type = "S" },
      { name = "resource", type = "S" }
    ]
    hash_key  = "id"
    range_key = "timestamp"
    global_secondary_indexes = [
      {
        name            = "UserIdIndex"
        hash_key        = "userId"
        range_key       = "timestamp"
        projection_type = "ALL"
      },
      {
        name            = "ActionIndex"
        hash_key        = "action"
        range_key       = "timestamp"
        projection_type = "ALL"
      },
      {
        name            = "ResourceIndex"
        hash_key        = "resource"
        range_key       = "timestamp"
        projection_type = "ALL"
      }
    ]
  }
}

ecr_repos = {
  sec_download = "sec_download"
}

eks_cluster_version = "1.32"

eks_node_instance_type = "t3.xlarge"

environment = "cloud_financial_dashboard"

sec_zip_file_url = "https://www.sec.gov/Archives/edgar/daily-index/bulkdata/submissions.zip"

vpc_cidr = "10.10.0.0/16"
