/// Production for MCL WEZORG instance
Class WEZORG.FoundationProduction Extends Ens.Production [ Not ProcedureBlock ]
{

XData ProductionDefinition
{
<Production Name="WEZORG.FoundationProduction" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description>FHIR Facade for RavenDB</Description>
  <ActorPoolSize>1</ActorPoolSize>
  <Item Name="InteropService" Category="" ClassName="HS.FHIRServer.Interop.Service" PoolSize="0" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="TargetConfigName">FHIRHandler</Setting>
  </Item>
  <Item Name="FHIRHandler" Category="" ClassName="WEZORG.BP.FHIR.FHIRHandler" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="TraceOperations">*FULL*</Setting>
  </Item>
  <Item Name="RavenDB" Category="" ClassName="WEZORG.BO.RavenDB" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="HTTPPort">80</Setting>
    <Setting Target="Adapter" Name="HTTPServer">live-test.ravendb.net</Setting>
  </Item>
  <Item Name="HS.Util.Trace.Operations" Category="FHIR" ClassName="HS.Util.Trace.Operations" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
