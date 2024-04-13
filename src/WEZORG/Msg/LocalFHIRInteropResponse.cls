/// LocalFHIRInteropResponse has been added to make the HS
Class WEZORG.Msg.LocalFHIRInteropResponse Extends HS.FHIRServer.Interop.Response [ StorageStrategy = "" ]
{

/// If this setting is not blank, then the system will expect there to be an operation named "HS.Util.Trace.Operations",
/// and it will direct trace messages to this operation.
Property TraceOperations As %String(MAXLEN = 100) [ Internal ];

/// Reference to BusinessProcess
/// Must inherist from HS.HC.Util.Trace.Helper
/// Stored as a String to avoid issues when being saved
Property Host As %String(MAXLEN = "") [ Internal ];

/// Create a new instance
ClassMethod Create(host As Ens.BusinessProcess, traceOperations As %String, responseFormatCode As %String) As WEZORG.Msg.LocalFHIRInteropResponse
{
	set response = ..%New()
    set response.Host = host
    set response.TraceOperations = traceOperations
	set response.Response.ResponseFormatCode = responseFormatCode
	set response.Response.Status = ##class(%CSP.REST).#HTTP200OK

    return response
}

/// Send quickstream to HSTracing
Method SendQuickStreamToHSTrace(quickStreamOut As HS.SDA3.QuickStream, iserror As %Boolean)
{
    if (..TraceOperations '= "")
    {
        if iserror || ((..TraceOperations '= "*ERRORSONLY*") && (..TraceOperations'="*MINIMAL*"))
        {
            do ..DoHSTrace(..Host, quickStreamOut, iserror)
        }
    }
}

/// Send quickstream to HSTracing
ClassMethod DoHSTrace(host As Ens.BusinessProcess, quickStreamOut As HS.SDA3.QuickStream, iserror As %Boolean)
{
    do host.HSTrace($$$CurrentClass, $$$CurrentMethod, "Response QuickStream", "quickStreamOut", quickStreamOut)
}

Storage Default
{
<Data name="LocalFHIRInteropResponseDefaultData">
<Subscript>"LocalFHIRInteropResponse"</Subscript>
<Value name="1">
<Value>TraceOperations</Value>
</Value>
<Value name="2">
<Value>Host</Value>
</Value>
</Data>
<DefaultData>LocalFHIRInteropResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
