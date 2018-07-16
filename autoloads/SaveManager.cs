using Godot;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.Serialization.Formatters.Binary;
using ICSharpCode.SharpZipLib.Zip;
using System.IO;
using File = System.IO.File;

//Need to use C# for this because GDscript can't zip files yet

public class SaveManager : Node
{
    private static Dictionary<string, Texture> Textures = new Dictionary<string, Texture>();

    public void ClearTextures()
    {
        Textures.Clear();
    }
    
    public void SetTexture(string name, ImageTexture tex)
    {
        Textures[name] = tex;
    }
    
    public void Save(string filename)
    {

        try
        {

            //see https://github.com/icsharpcode/SharpZipLib/blob/master/samples/ICSharpCode.SharpZipLib.Samples/cs/CreateZipFile/CreateZipFile.cs

            using (ZipOutputStream zipStream = new ZipOutputStream(File.Create(filename)))
            {
                zipStream.SetLevel(1); // 0 - store only to 9 - means best compression (9 = slow as hell)

               
                //Put info
                zipStream.PutNextEntry(new ZipEntry("info") {DateTime = DateTime.Now});
                var writer = new StreamWriter(zipStream);
                writer.WriteLine("version=1"); //TODO write json or something here
                writer.Flush(); //important (also DO NOT CLOSE the stream writer)

                //Put texture slots
                foreach (var pair in Textures)
                {
                    var name = pair.Key;
                    var texture = pair.Value;

                    GD.Print($"Compressing {name}...");

                    zipStream.PutNextEntry(new ZipEntry($"slots/{name}") {DateTime = DateTime.Now});
                    var dictionary = texture.GetData().Data;

                    new BinaryFormatter().Serialize(zipStream, dictionary);

                    // try https://aloiskraus.wordpress.com/2017/04/23/the-definitive-serialization-performance-guide/
                }

                zipStream.Finish();
                zipStream.Close(); //maybe unneeded?

                GD.Print($"Saved to {filename}!");
            }
        }
        catch (Exception e)
        {
            GD.Print($"Saving to {filename} failed: {e}");
        }
    }

    public List<ImageTexture> Load(string filename)
    {
        
        GD.Print("load");


        var textures = new List<ImageTexture>();

        using (ZipInputStream s = new ZipInputStream(File.OpenRead(filename)))
        {
            ZipEntry entry;
            
            
            while ((entry = s.GetNextEntry()) != null) {
                GD.Print($"Name : {entry.Name}");
                GD.Print($"Uncompressed : {entry.Size/1024.0/1024.0}MB");
                GD.Print($"Compressed   : {entry.CompressedSize/1024.0/1024.0}MB");

                if (!entry.IsFile) continue;
                if (!entry.Name.StartsWith("slots/")) continue;

                var dict = (Dictionary<object, object>) new BinaryFormatter().Deserialize(s);
                Debug.Assert(1 == s.Read(new byte[1], 0, 1)); //DO NOT REMOVE THIS! REQUIRED!!!
                
                ImageTexture tex = new ImageTexture();
                tex.CreateFromImage(new Image {Data = dict});
                
                textures.Add(tex);

            }
        }
   

        GD.Print("Done loading zip stuff");

        return textures;
    }
}
