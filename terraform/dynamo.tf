resource "aws_dynamodb_table" "this" {
  for_each = var.dynamo_tables

  name         = "${var.environment}_${each.key}"
  billing_mode = "PAY_PER_REQUEST"

  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  hash_key  = each.value.hash_key
  range_key = lookup(each.value, "range_key", null)

  dynamic "global_secondary_index" {
    for_each = each.value.global_secondary_indexes != null ? each.value.global_secondary_indexes : []

    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = try(global_secondary_index.value.range_key, null)
      projection_type = global_secondary_index.value.projection_type
    }
  }

  stream_enabled   = lookup(each.value, "stream_enabled", false)
  stream_view_type = lookup(each.value, "stream_view_type", null)

  tags = var.tags
}
