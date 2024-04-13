/// Help normalize a method name and check if it exists 
Class WEZORG.Util.MethodHelper
{

/// Normalize Parameter Name
ClassMethod NormalizeParamName(prefix As %String = "-", paramName As %String) As %Status
{
	return ##class(HS.FHIRServer.Util.FHIRQueryUtils).NormalizeParamName(prefix _ paramName)
}

/// Check if a method exists
ClassMethod GetNormalizedMethodNameAndCheckExists(prefix As %String, code As %String) As %String
{
	set classname = $CLASSNAME()
	set tMethod = ..NormalizeParamName(prefix, code)
	
	// Does the method exists?
	write "Check ##class(" _ classname _ ")." _ tMethod _ "():"
	set compMethod = ##class(%Dictionary.CompiledMethod).%OpenId(classname _ "||" _ tMethod)
	
    if (compMethod = "")
    {
    	write " not"
        set tMethod = ""
    }

    write " found",!

	kill compMethod

    return tMethod
}

}
