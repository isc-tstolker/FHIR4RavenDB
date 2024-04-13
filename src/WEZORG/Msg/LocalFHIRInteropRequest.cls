/// Local FHIR Interop request
Class WEZORG.Msg.LocalFHIRInteropRequest Extends HS.FHIRServer.Interop.Request
{

Parameter RESPONSECLASSNAME As %String = "AeoNoseConnector.Msg.Response.LocalFHIRInteropResponse";

/// ResourceType
Property ResourceType As %String(MAXLEN = 48);

/// ResourceId
Property ResourceId As %String(MAXLEN = 48);

/// Create new  from HS.FHIRServer.Interop.Request 
ClassMethod CreateLocalInteropRequest(pInteropRequest As HS.FHIRServer.Interop.Request) As WEZORG.Msg.LocalFHIRInteropRequest
{
    set request = ..%New()

    set request.Request = pInteropRequest.Request
    set request.QuickStreamId = pInteropRequest.QuickStreamId
    set request.ResourceType = $PIECE(pInteropRequest.Request.RequestPath, "/", 1)
    set request.ResourceId = $PIECE(pInteropRequest.Request.RequestPath, "/", 2)
   
    return request
}

Storage Default
{
<Data name="LocalFHIRInteropRequestDefaultData">
<Subscript>"LocalFHIRInteropRequest"</Subscript>
<Value name="1">
<Value>ResourceType</Value>
</Value>
<Value name="2">
<Value>ResourceId</Value>
</Value>
</Data>
<DefaultData>LocalFHIRInteropRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
