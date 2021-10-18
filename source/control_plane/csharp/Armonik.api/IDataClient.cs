/* IDataClient.cs is part of the Armonik.sdk solution.

   Copyright (c) 2021-2021 ANEO.
     W. Kirschenmann (https://github.com/wkirschenmann)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

*/



namespace Armonik.sdk
{
  /// <summary>
  /// Interface to implement to allow the Armonik.sdk components to connect to a grid scheduler
  /// </summary>
  public interface IDataClient
  {
    /// <summary>
    /// Fetch the data corresponding to the given key.
    /// </summary>
    /// <param name="key">Key of data to fetch.</param>
    /// <returns></returns>
    byte[] GetData(string key);

    /// <summary>
    /// Sore the data corresponding to a given key
    /// </summary>
    /// <param name="key">The key corresponding to the object to store</param>
    /// <param name="data">The data to store.</param>
    void StoreData(string key, byte[] data);
  }
}
