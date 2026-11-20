$source = @"
using System;
using System.IO;
using System.Threading.Tasks;
using Windows.Data.Pdf;
using Windows.Storage;

public class PdfRenderer
{
    public static async Task RenderPdfAsync(string pdfPath, string outputDir)
    {
        StorageFile file = await StorageFile.GetFileFromPathAsync(pdfPath);
        PdfDocument doc = await PdfDocument.LoadFromFileAsync(file);
        StorageFolder folder = await StorageFolder.GetFolderFromPathAsync(outputDir);

        for (uint i = 0; i < doc.PageCount; i++)
        {
            using (PdfPage page = doc.GetPage(i))
            {
                StorageFile outputFile = await folder.CreateFileAsync(
                    "page_" + (i + 1) + ".png",
                    CreationCollisionOption.ReplaceExisting);

                using (var stream = await outputFile.OpenAsync(FileAccessMode.ReadWrite))
                {
                    PdfPageRenderOptions opt = new PdfPageRenderOptions();
                    opt.DestinationWidth = (uint)(page.Dimensions.ArtBox.Width * 2.5);
                    await page.RenderToStreamAsync(stream, opt);
                    await stream.FlushAsync();
                }
            }
            Console.WriteLine("Rendered page " + (i + 1));
        }
    }
}
"@

$references = @(
    "System.Runtime.WindowsRuntime",
    "C:\Windows\System32\WinMetadata\Windows.Data.Pdf.winmd",
    "C:\Windows\System32\WinMetadata\Windows.Storage.winmd",
    "C:\Windows\System32\WinMetadata\Windows.Foundation.winmd"
)

Add-Type -TypeDefinition $source -ReferencedAssemblies $references -Language CSharp

$pdf = "C:\Users\User01\.gemini\antigravity\brain\af18e558-85da-49ae-9eb0-4c9b6d7b02ae\.user_uploaded\media_1795153661234_0b7c7c83.pdf"
$out = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\pdf_pages"
if (-not (Test-Path $out)) { New-Item -ItemType Directory -Path $out -Force | Out-Null }

[PdfRenderer]::RenderPdfAsync($pdf, $out).GetAwaiter().GetResult()
Write-Host "All pages rendered successfully!"
