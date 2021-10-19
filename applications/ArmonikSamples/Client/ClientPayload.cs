using System;
using System.Collections;
using System.Text.Json;
using System.Collections.Generic;
using System.Runtime.Serialization;


public class ClientPayload {
    public string taskType {get;set;}
    public List<int> numbers{get;set;}
    public int result{get;set;}

    public byte[] serialize()
    {
        string jsonString = JsonSerializer.Serialize(this);
        return System.Text.Encoding.ASCII.GetBytes(stringToBase64(jsonString));
    }

    public static ClientPayload deserialize(byte[] payload)
    {
        if (payload == null || payload.Length == 0)
        {
            return new ClientPayload {taskType = "No data", numbers = new List<int>(), result = -1};
        }
        var str = System.Text.Encoding.ASCII.GetString(payload);
        return JsonSerializer.Deserialize<ClientPayload>(Base64ToString(str));
    }

    private static string stringToBase64(string serializedJson)
    {
        var serializedJsonBytes = System.Text.Encoding.UTF8.GetBytes(serializedJson);
        var serializedJsonBytesBase64 = System.Convert.ToBase64String(serializedJsonBytes);
        return serializedJsonBytesBase64;
    }

    private static string Base64ToString(string base64)
    {
        var c = System.Convert.FromBase64String(base64);
        return System.Text.Encoding.ASCII.GetString(c);
    }
}