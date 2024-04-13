/// Resource properties helper
Class WEZORG.Util.ResourceProperties
{

/// Order  FHIR resource properties in the followin order:
/// - resourceType
/// - id
/// - meta
/// - extension
ClassMethod FHIROrderResourceProperties(resource As %DynamicObject) As %DynamicObject
{
    return ..JsonOrderProperties(resource, [ "resourceType", "id", "meta", "extension" ])
}

/// Order json object properties in the specified order
ClassMethod JsonOrderProperties(object As %DynamicObject, order As %DynamicArray) As %DynamicObject
{
    #dim newObject as %DynamicObject = {}

    // First set the ordered properties in the new object 

    for index = 0:1:order.%Size() - 1
    {
        set name = order.%Get(index)
        set done(name) = 1
        set type = object.%GetTypeOf(name)

        if $EXTRACT(type, 1, 2) '= "un" // unassigned
        {
            do newObject.%Set(name, object.%Get(name)) 
        }
    }
    
    // Now copy remaining attributes not specified
    #dim iterator As %Iterator.Object = object.%GetIterator()

    while iterator.%GetNext(.name, .value, .type)
    {
        if '$DATA(done(name))
        {
            set type = object.%GetTypeOf(name)

            if (type = "boolean") || (type = "number") || (type = "null")
            {
                do newObject.%Set(name, value, type)
            }
            else
            {
                do newObject.%Set(name, value)
            }
        }
    }

    return newObject
}

}
