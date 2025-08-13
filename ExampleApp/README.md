# Nolock OCR Swift Client - Example Application

This example application demonstrates how to use the Nolock OCR Swift Client library.

## Building

```bash
swift build
```

## Running

### Basic Example
```bash
./.build/debug/ExampleApp
```

### Integration Tests
```bash
./.build/debug/ExampleApp --test
# or
./.build/debug/ExampleApp -t
```

### Date Parsing Test
```bash
./.build/debug/ExampleApp --date-test
# or
./.build/debug/ExampleApp -d
```

## Date Format Fix

The client has been updated to handle the date format returned by the API (`yyyy-MM-dd'T'HH:mm:ss`). The `OpenISO8601DateFormatter` now supports:
- Standard ISO8601 with milliseconds and timezone
- ISO8601 without timezone (API's format)
- ISO8601 without seconds
- Date only format

## Test Image

For testing, create a test check image named `test-check.jpg` in the current directory. The date parsing test will use this image to verify OCR functionality.