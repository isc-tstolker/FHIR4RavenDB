/// Setup Methods
Class WEZORG.Setup Extends %RegisteredObject
{

/// Add FHIR Interop Service
ClassMethod AddInteropService()
{
    new $NAMESPACE
    set $NAMESPACE = "WEZORG"

    do ##class(HS.FHIRServer.Installer).InteropAdapterConfig("/wezorg/fhir/r4")
}

}
