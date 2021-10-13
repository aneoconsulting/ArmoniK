
/// <summary>
/// Provides the context for the task that is bound to the given service invocation
/// </summary>
public class TaskContext
{
    public string TaskId { get; set; }
    public byte[] payload_;


    public string SessionId { get; }

    public string clientLibVersion {get; set; }



/// <summary>
/// The customer payload to deserialize by the customer
/// </summary>
/// <value></value>
    public byte[] TaskInput
    {
        get { return payload_; }

        set { payload_ = value; }
    }
}