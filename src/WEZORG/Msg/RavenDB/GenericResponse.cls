/// Generic Response Class
Class WEZORG.Msg.RavenDB.GenericResponse Extends Ens.Response [ Inheritance = left, ProcedureBlock ]
{

Property body As %Stream.GlobalCharacter;

Property headers As array Of %String(MAXLEN = 128, TRUNCATE = 1);

Property httpStatusCode As %Integer;

Property operation As %String(MAXLEN = 128, TRUNCATE = 1);

/// Status for parts of the response handling like JSON Parsing. 
/// This allows for returning the response body that will not be returned if the request fails.
Property status As %Status;

/// Load properties from response
Method LoadFromResponse(httpResponse As %Net.HttpResponse, caller As %String = "") As %Status
{
	set sc = $$$OK
	do ..body.CopyFrom(httpResponse.Data)
	set ..httpStatusCode = httpResponse.StatusCode
	set ..operation = caller
	set key = ""

	for
	{
		set key = $Order(httpResponse.Headers(key), 1, headerValue)
		if key = ""
		{
			quit
		}

		do ..headers.SetAt(headerValue, key)
	}

	return sc
}

Storage Default
{
<Data name="GenericResponseDefaultData">
<Subscript>"GenericResponse"</Subscript>
<Value name="1">
<Value>body</Value>
</Value>
<Value name="2">
<Value>httpStatusCode</Value>
</Value>
<Value name="3">
<Value>operation</Value>
</Value>
<Value name="4">
<Value>status</Value>
</Value>
</Data>
<Data name="headers">
<Attribute>headers</Attribute>
<Structure>subnode</Structure>
<Subscript>"WEZORG.Msg.RavenDB.GenericResponse.headers"</Subscript>
</Data>
<DefaultData>GenericResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
