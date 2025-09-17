# S5 Diff Template - Scraper Contract Compliance Checklist

**Generated:** 2025-09-17
**Purpose:** Verify scraper output matches event contracts
**Usage:** Check each item when reviewing scraper implementations

## Pre-Implementation Checklist

### 📋 Contract Review
- [ ] Read S5_event_contracts.yaml for your entity type
- [ ] Review field mappings (source → database)
- [ ] Understand required vs optional fields
- [ ] Note validation rules and patterns
- [ ] Check batch size recommendations

### 📊 Sample Data Review
- [ ] Examine golden samples in S5_input_examples/
- [ ] Test parsing the NDJSON format
- [ ] Validate against sample records
- [ ] Review edge cases in validation_test_cases.json

## Implementation Checklist

### 🔧 Core Requirements

#### Data Format
- [ ] Output is NDJSON (one JSON object per line)
- [ ] UTF-8 encoding without BOM
- [ ] No pretty printing or indentation
- [ ] Each line is a valid JSON object
- [ ] File ends with newline character

#### Field Compliance

##### DTC Codes (GitHub)
- [ ] `dtc_code` matches pattern `^[PBCU]\d{4}$`
- [ ] `description` is non-empty string
- [ ] `category` is one of: powertrain, body, chassis, network
- [ ] `source` includes repository URL
- [ ] `extraction_metadata.extracted_at` is ISO 8601 timestamp
- [ ] `extraction_metadata.confidence_score` is 0.0-1.0
- [ ] Field mapping: `error_code` → `dtc_code`
- [ ] Field mapping: `repo_url` → `source_details.repository_url`

##### Reddit Diagnostic Posts
- [ ] `url` matches Reddit URL pattern
- [ ] `timestamp` is ISO 8601 format
- [ ] `source_type` is "post" or "comment"
- [ ] `equipment.make` populated when available
- [ ] `diagnostic_codes` array contains valid DTC codes
- [ ] Field mapping: `permalink` → `url`
- [ ] Field mapping: `car_make` → `equipment.make`
- [ ] Field mapping: `error_codes` → `diagnostic_codes`

##### YouTube Repair Videos
- [ ] `video_id` matches YouTube ID pattern (11 chars)
- [ ] `title` is non-empty, max 200 chars
- [ ] `channel` information populated
- [ ] `duration_seconds` is positive integer
- [ ] `published_at` is ISO 8601 timestamp
- [ ] Field mapping: `videoId` → `video_id`
- [ ] Field mapping: `channelTitle` → `channel`
- [ ] Field mapping: `car_make` → `vehicle_info.make`

##### Equipment Registry
- [ ] `id` is valid UUID v4
- [ ] `identification_primary` populated (VIN/serial)
- [ ] `equipment_category` from allowed enum
- [ ] VIN validation for automotive (17 chars, no I/O/Q)
- [ ] GPS coordinates in valid range if provided
- [ ] Field mapping: `vin` → `identification_primary`
- [ ] Field mapping: `make` → `equipment_details.manufacturer`

### 🔍 Validation Requirements

#### Data Quality
- [ ] No NULL bytes in strings
- [ ] No control characters (except \n, \r, \t)
- [ ] Proper escaping of quotes and backslashes
- [ ] Valid JSON structure (test with jq or similar)
- [ ] Timestamps include timezone (preferably UTC)

#### Batch Processing
- [ ] Batch sizes match recommendations (1000 for most entities)
- [ ] Deduplication by specified key field
- [ ] Files compressed with gzip when > 10MB
- [ ] Filename includes entity type and timestamp

#### Error Handling
- [ ] Invalid records logged to separate file
- [ ] Validation errors include line number
- [ ] Partial batch failures don't lose valid records
- [ ] Retry logic for transient failures

## Post-Implementation Verification

### 🧪 Testing

#### Unit Tests
- [ ] Parse golden samples successfully
- [ ] Validate all required fields present
- [ ] Reject invalid DTC codes
- [ ] Handle missing optional fields
- [ ] Process edge cases from validation_test_cases.json

#### Integration Tests
- [ ] End-to-end scraping produces valid NDJSON
- [ ] Output passes S4_runner.py validation
- [ ] Successfully imports to BigQuery staging
- [ ] No data loss during pipeline

#### Performance Tests
- [ ] Meet throughput targets (records/hour)
- [ ] Memory usage within limits
- [ ] File sizes reasonable for batch size
- [ ] Compression ratios acceptable

### 📈 Monitoring

#### Metrics to Track
- [ ] Records scraped per hour
- [ ] Validation pass rate (target >99%)
- [ ] Duplicate rate (should be <5%)
- [ ] Error rate by error type
- [ ] Average processing time per record

#### Alerts to Configure
- [ ] Validation failure rate > 1%
- [ ] No data received in 24 hours
- [ ] Batch size exceeds limits
- [ ] Malformed JSON detection
- [ ] Schema drift detection

## Final Checklist

### 🚀 Production Readiness

#### Documentation
- [ ] README updated with scraper details
- [ ] Field mapping documented
- [ ] Error codes documented
- [ ] Retry policies documented
- [ ] Contact information provided

#### Deployment
- [ ] Config uses S5_event_contracts.yaml
- [ ] Logging configured appropriately
- [ ] Credentials securely stored
- [ ] Rate limiting implemented
- [ ] Graceful shutdown handling

#### Compliance
- [ ] GDPR compliance for personal data
- [ ] Robots.txt respected
- [ ] API rate limits honored
- [ ] Terms of service followed
- [ ] Data retention policies implemented

## Sign-Off

### Reviewer Checklist
- [ ] Code review completed
- [ ] Sample output validated
- [ ] Performance benchmarks met
- [ ] Security review passed
- [ ] Documentation complete

**Scraper Developer:** ___________________________ Date: __________

**Data Engineer:** ___________________________ Date: __________

**QA Engineer:** ___________________________ Date: __________

---

## Quick Reference

### File Locations
- Event Contracts: `NMD/S5_event_contracts.yaml`
- Golden Samples: `NMD/S5_input_examples/*.ndjson`
- Validation Runner: `NMD/S4_runner.py`
- Test Cases: `NMD/S5_input_examples/validation_test_cases.json`

### Validation Command
```bash
# Validate scraper output
python3 NMD/S4_runner.py \
  --input your_scraper_output.ndjson \
  --entity dtc_codes_github \
  --fail-on error
```

### Common Issues
1. **Invalid JSON**: Use `jq` to validate: `jq -c . < output.ndjson`
2. **Wrong encoding**: Convert to UTF-8: `iconv -f ISO-8859-1 -t UTF-8`
3. **Missing fields**: Check required fields in event contracts
4. **Invalid timestamps**: Use ISO 8601 with timezone
5. **Field mapping errors**: Review source → database mappings

---

**Note:** This checklist should be reviewed for each scraper implementation and updated as new requirements emerge.