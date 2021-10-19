using System;
using System.Collections;
using System.Text.Json;
using System.Collections.Generic;
using System.Runtime.Serialization;


public class ClientPayload {
    public string taskType;
    public List<int> numbers;
    public int result;

    public byte[] serialize() {
        string jsonString = JsonSerializer.Serialize(this);
        return System.Text.Encoding.ASCII.GetBytes(stringToBase64(jsonString));
    }

    public static ClientPayload deserialize(byte[] payload) {
        var str = System.Text.Encoding.ASCII.GetString(payload);
        return JsonSerializer.Deserialize<ClientPayload>(Base64ToString(str));
    }

    private static string stringToBase64(string serializedJson) {
        var serializedJsonBytes = System.Text.Encoding.UTF8.GetBytes(serializedJson);
        var serializedJsonBytesBase64 = System.Convert.ToBase64String(serializedJsonBytes);
        return serializedJsonBytesBase64;
    }

    private static string Base64ToString(string base64) {
        var c = System.Convert.FromBase64String(base64);
        return System.Text.Encoding.ASCII.GetString(c);
    }
}