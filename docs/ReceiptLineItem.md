# ReceiptLineItem

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**description** | **String** | Item description or name | [optional] 
**sku** | **String** | Stock keeping unit or product code | [optional] 
**quantity** | **Double** | Quantity purchased | [optional] 
**unit** | **String** | Unit of measurement - can be enum or string for flexibility | [optional] 
**unitPrice** | **Double** | Price per unit - converted from string to decimal for C# type safety | [optional] 
**totalPrice** | **Double** | Total price for this line item - converted from string to decimal for C# type safety | [optional] 
**discounted** | **Bool** | Whether the item was discounted | [optional] 
**discountAmount** | **Double** | Amount of discount applied - converted from string to decimal for C# type safety | [optional] 
**category** | **String** | Product category | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


