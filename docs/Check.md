# Check

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**checkNumber** | **String** | Check number or identifier | [optional] 
**date** | **Date** | Date on the check (ISO 8601 format when transmitted as string) | [optional] 
**payee** | **String** | Person or entity to whom the check is payable | [optional] 
**payer** | **String** | Person or entity who wrote/signed the check | [optional] 
**amount** | **Double** | Dollar amount of the check - converted from string to decimal for C# type safety | [optional] 
**amountText** | **String** | Written amount text on the check | [optional] 
**memo** | **String** | Memo or note on the check | [optional] 
**bankName** | **String** | Name of the bank issuing the check | [optional] 
**routingNumber** | **String** | Bank routing number (9 digits) | [optional] 
**accountNumber** | **String** | Bank account number | [optional] 
**checkType** | [**CheckType**](CheckType.md) |  | [optional] 
**accountType** | [**BankAccountType**](BankAccountType.md) |  | [optional] 
**signature** | **Bool** | Whether the check appears to be signed | [optional] 
**signatureText** | **String** | Text of the signature if readable | [optional] 
**fractionalCode** | **String** | Fractional code on the check (alternative routing identifier) | [optional] 
**micrLine** | **String** | Full MICR (Magnetic Ink Character Recognition) line on the bottom of check | [optional] 
**metadata** | [**CheckMetadata**](CheckMetadata.md) |  | [optional] 
**confidence** | **Double** | Overall confidence score of the extraction | [optional] 
**isValidInput** | **Bool** | Indicates if the input appears to be a valid check image. False if the system has detected potential hallucinations | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


