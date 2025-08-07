# Receipt

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**merchant** | [**MerchantInfo**](MerchantInfo.md) |  | [optional] 
**receiptNumber** | **String** | Receipt or invoice number | [optional] 
**receiptType** | **String** | Type of receipt | [optional] 
**timestamp** | **Date** | Date and time of transaction (ISO 8601 format when transmitted as string) | [optional] 
**paymentMethod** | **String** | Method of payment - can be enum or string for flexibility | [optional] 
**totals** | [**ReceiptTotals**](ReceiptTotals.md) |  | [optional] 
**currency** | **String** | ISO 4217 currency code (3-letter codes like USD, EUR, GBP) | [optional] 
**items** | [ReceiptLineItem] | List of line items on the receipt | [optional] 
**taxes** | [ReceiptTaxItem] | Breakdown of taxes | [optional] 
**payments** | [ReceiptPaymentMethod] | Details about payment methods used | [optional] 
**notes** | **[String]** | Additional notes or comments | [optional] 
**metadata** | [**ReceiptMetadata**](ReceiptMetadata.md) |  | [optional] 
**confidence** | **Double** | Overall confidence score of the extraction | [optional] 
**isValidInput** | **Bool** | Indicates if the input appears to be a valid receipt image. False if the system has detected potential hallucinations | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


