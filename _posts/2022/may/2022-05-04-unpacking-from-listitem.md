---
layout: post
title: "The best way to access SP ListItem"
date: 2022-05-04
tags: |
  oop
  csharp
---

During my work with the SharePoint client library, I have encountered many different approaches to working with it. We can consider SharePoint as a niche technology, in some ways already obsolete. But unfortunately, after many years of using this library have not had time to develop good approaches to use, with clear examples and good documentation. With this article, I want to run a series of articles about working with _Microsoft.SharePoint.Client_ library.

One of the most popular tasks is to get an item from a list and get its fields then. Let's look at the situation of obtaining fields of the ListItem object.
``` csharp
using (var context = new ClientContext(url))
{
  List list = context.Web.GetList("Lists/items");
  ListItem item = list.GetItemById(1);

  context.Load(item);
  context.ExecuteQuery();
  
  // Here is the problem
  string textField =  Convert.ToString(item["TestItemText"]);
  double numberField = Convert.ToDouble(item["TestItemNumber"]);
  DateTime dateField = Convert.ToDateTime(item["TestItemDate"]);

  return new { Text = textField, Number = numberField };
}
```
> Static methods are like the cancer of object-oriented programming software: once we let them settle in our code, we cannot get rid of them - their colony will only grow. Just avoid them in principle.

You may not believe me, but this is the most common way of obtaining values that I have encountered. The problem here is that we already know what type to expect in the _ListItem_, based on the type we set in the settings of our List. The relation of .NET types to field types in SharePoint is below.

| C# Type          | SharePoint Type    |
| string           | Text, Note, Choice |
| double?          | Number             |
| decimal?         | Currency           |
| DateTime?        | Date and time      |
| bool?            | Boolean            |
| FieldUserValue   | User or Group      |
| FieldLookupValue | Lookup             |
| FieldUrlValue    | File or URL        |

As you can see, all fields allow null values. We will have different results in case null value, if we use a _static class Convert_ and if we use a usual unpacking. 
``` csharp
// is true
bool isNull = item["TestItemText"] == null; 

// string.Empty
string convertedText = Convert.ToString(item["TestItemText"]); 

// null
string castedText = (string) item["TestItemText"];
```
To explain this behavior, we need to look at the source code of the _Convert.ToString_ method.

``` csharp
[__DynamicallyInvokable]
public static string ToString(object value) => 
	Convert.ToString(value, (IFormatProvider) null);

[__DynamicallyInvokable]
public static string ToString(object value, IFormatProvider provider)
{
  switch (value)
  {
    case IConvertible convertible:
      return convertible.ToString(provider);
    case IFormattable formattable:
      return formattable.ToString((string) null, provider);
    // in that case
    case null:
      return string.Empty;
    default:
      return value.ToString();
  }
}
```
## Fail Fast and Fail Safe

I would rather fail faster with Cast error when testing the method than get unexpected values somewhere in other services. If we have made sure with SharePoint types, we can simply convert the object type to the desired value type. Just don’t forget to set a nullable value type or set a desirable default value, in case of null.

``` csharp
var textField = (string) item["TestItemText"];
var numberField = (double?) item["TestItemNumber"];

// desirable default value
var dateField = (DateTime?) item["TestItemDate"] ?? new DateTime(2022, 01, 01);
```

Furthermore, we are able to add a little syntactic sugar and simplify obtaining values from the ListItem and implement the TryGet pattern for exception handling.

``` csharp
public static class Extensions
{
    public static T GetFieldValue<T>(this ListItem item, string fieldName) => (T) item[fieldName];

    public static bool TryGetFieldValue<T>(this ListItem item, string fieldName, out T value)
    {
        value = default; 
        
        try
        {
            value = (T) item[fieldName];

            return true;
        }
        catch
        {
            return false;
        }
    }
}

var textField = item.GetFieldValue<string>("TestItemText");
var numberField = item.GetFieldValue<double?>("TestItemNumber");
if (item.TryGetFieldValue<DateTime>("TestItemDate", out var dateField))
{
    _logger.LogInformation("Unexpected null value or type error with TestItemDate field");
}
```
Agree, it looks much nicer than before.

## What else can be improved?

The solution that we considered fits perfectly with the Rich Domain Model in small projects where we don't always need to do mapping of SharePoint entities and domain entities. But in large projects, we have to deal with a large number of entities and the process of manual mapping becomes not the most optimal solution.
I have ideas about developing automatic mapping for SharePoint entities similar to _System.Text.Json Serializer_. 

What do you think, will it be useful?