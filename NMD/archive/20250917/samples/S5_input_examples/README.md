# S5 Input Examples - Golden Sample Data Files

**Generated:** 2025-09-17
**Version:** 1.0
**Purpose:** Reference implementation data for DiagnosticPro Phase S5 scrapers

## Overview

This directory contains golden sample data files that demonstrate the exact data formats expected by the S5 event contracts. These samples serve as reference implementations for scraper developers and validation testing.

## File Structure

```
S5_input_examples/
├── README.md                              # This documentation
├── dtc_codes_github.ndjson               # 5 GitHub DTC code samples
├── reddit_diagnostic_posts.ndjson       # 5 Reddit diagnostic post samples
├── youtube_repair_videos.ndjson         # 5 YouTube repair video samples
├── equipment_registry.ndjson            # 5 Equipment registry samples
├── dtc_codes_github.parquet.json        # Parquet equivalent (JSON format)
├── reddit_diagnostic_posts.parquet.json # Parquet equivalent (JSON format)
├── youtube_repair_videos.parquet.json   # Parquet equivalent (JSON format)
├── equipment_registry.parquet.json      # Parquet equivalent (JSON format)
├── validation_test_cases.json           # Edge cases and boundary conditions
└── convert_to_parquet.py                 # Conversion utility script
```

## Sample Data Description

### DTC Codes GitHub (`dtc_codes_github.ndjson`)
Contains 5 diverse diagnostic trouble code records from GitHub repositories:

1. **P0301** - Engine misfire (Powertrain) with comprehensive details
2. **B1342** - Airbag circuit issue (Body) with safety critical classification
3. **C0035** - ABS wheel speed sensor (Chassis) with moderate severity
4. **U0100** - ECM communication loss (Network) with critical severity
5. **P2004** - Intake manifold issue (Powertrain) with minor severity

**Key Features:**
- All DTC categories represented (P, B, C, U)
- Various severity levels (informational → critical)
- Different automotive systems (engine, airbag, brakes, communication)
- Comprehensive optional fields (symptoms, causes, solutions)
- Realistic GitHub source metadata

### Reddit Diagnostic Posts (`reddit_diagnostic_posts.ndjson`)
Contains 5 realistic automotive diagnostic discussions:

1. **Honda Civic P0301** - Post with misfire diagnosis request
2. **Ford Focus Transmission** - Comment with solution and cost information
3. **BMW E90 Overheating** - Post with VIN and detailed equipment info
4. **Chevy Silverado Diesel** - Post about black smoke with high mileage
5. **Toyota Prius Airbag** - Comment with part replacement details

**Key Features:**
- Both posts and comments represented
- Various vehicle makes/models/years (2008-2019)
- Different diagnostic scenarios (engine, transmission, cooling, emissions, safety)
- Resolution tracking with costs and parts
- Realistic Reddit URLs and metadata

### YouTube Repair Videos (`youtube_repair_videos.ndjson`)
Contains 5 educational automotive repair videos:

1. **Honda Civic P0301 Fix** - DIY misfire repair tutorial
2. **BMW E90 Water Pump** - Advanced cooling system repair
3. **Ford F-150 Transmission Service** - Maintenance procedure
4. **Toyota Prius Hybrid Battery** - Professional-level diagnosis
5. **VW TDI DPF Cleaning** - Diesel emissions system repair

**Key Features:**
- Various difficulty levels (beginner → professional)
- Different repair types (diagnostic, replacement, maintenance, troubleshooting)
- Realistic YouTube metadata (views, likes, comments)
- Transcript availability variations
- Tool requirements and cost estimates

### Equipment Registry (`equipment_registry.ndjson`)
Contains 5 diverse equipment tracking records:

1. **2022 Honda Accord** - Standard passenger vehicle with VIN
2. **2008 BMW 328i** - Luxury sedan with detailed specifications
3. **CAT 320 Excavator** - Heavy equipment with serial number
4. **iPhone 14 Pro** - Electronics with IMEI identifier
5. **GE LM2500 Turbine** - Industrial machinery with asset tag

**Key Features:**
- Multiple equipment categories (automotive, heavy equipment, electronics, machinery)
- Various identification types (VIN, serial number, IMEI, asset tag)
- Different scales (phone → industrial turbine)
- Geographic diversity (NY, CA, CO, TX)
- Economic data (MSRP, depreciation rates)

## Validation Test Cases

The `validation_test_cases.json` file contains comprehensive edge cases:

### Boundary Conditions
- **Maximum field lengths** - Testing 500-char descriptions, 40k-char content
- **Array limits** - Testing maximum array sizes (500 tags, 20 causes)
- **Numeric boundaries** - Testing min/max values (GPS coordinates, voltage, weight)
- **Date boundaries** - Testing Reddit founding date (2005-06-23)

### International Support
- **Unicode characters** - Multi-language content (French, Russian, Japanese)
- **Special characters** - European automotive terms with umlauts/accents
- **Character encoding** - UTF-8 validation across all text fields

### Data Quality Cases
- **Missing optional fields** - Testing minimal valid records
- **Empty arrays** - Testing behavior with empty optional arrays
- **Format validation** - Testing VIN, DTC code, UUID, URL formats

## Usage Instructions

### For Scraper Developers
1. **Reference Implementation**: Use these samples as templates for your scraper output
2. **Field Mapping**: Follow the exact field names and data types shown
3. **Validation**: Test your scrapers against the validation test cases
4. **Format Compliance**: Ensure NDJSON output matches these examples

### For Data Pipeline Engineers
1. **Schema Validation**: Use samples to test import pipeline validation
2. **Parquet Conversion**: Reference the parquet equivalents for data lake storage
3. **Edge Case Handling**: Test pipeline robustness with validation test cases
4. **Quality Assurance**: Verify data transformations preserve sample integrity

### For QA Testing
1. **Golden Standard**: Use samples as expected output for regression testing
2. **Boundary Testing**: Validate system behavior with edge cases
3. **International Testing**: Verify Unicode and special character handling
4. **Performance Testing**: Use samples for load testing data processing pipelines

## Data Quality Standards

### Required Field Coverage
- All samples include 100% of required fields per S5 contracts
- Optional fields demonstrate realistic usage patterns
- Field mappings follow standard automotive industry conventions

### Diversity Metrics
- **Vehicle Coverage**: 8 different manufacturers across samples
- **Year Range**: 2008-2022 model years represented
- **System Coverage**: All major automotive systems included
- **Severity Range**: All DTC severity levels represented

### Realistic Data
- **Authentic DTCs**: All diagnostic codes are real automotive trouble codes
- **Valid VINs**: VIN numbers follow proper format and check digit rules
- **Realistic Costs**: Repair costs reflect current market pricing
- **Accurate Timestamps**: All timestamps use proper ISO 8601 format

## Integration Points

### With S5 Event Contracts
- Samples exactly match field definitions in `S5_event_contracts.yaml`
- All validation rules are demonstrated and tested
- Field mappings align with scraper transformation requirements

### With BigQuery Schema
- Data types match target table schemas
- Nested objects follow proper JSON structure for BigQuery import
- Array fields demonstrate proper REPEATED field handling

### With Scraper Systems
- File naming follows batch export conventions
- NDJSON format matches scraper output requirements
- Batch metadata fields included for pipeline tracking

## Maintenance

### Updating Samples
1. Modify NDJSON files to reflect contract changes
2. Regenerate Parquet equivalents using `convert_to_parquet.py`
3. Update validation test cases for new edge conditions
4. Refresh README.md documentation

### Version Control
- Samples are versioned with S5 event contracts
- Breaking changes require new sample generation
- Backward compatibility maintained for stable fields

---

**Contact:** Database Schema Architect
**Last Updated:** 2025-09-17
**Related Files:** `../S5_event_contracts.yaml`