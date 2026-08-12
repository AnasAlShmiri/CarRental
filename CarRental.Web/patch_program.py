p = "Program.cs"
s = open(p).read()
tail = """
app.MapPost("/test-echo", async (HttpContext ctx) =>
{
    ctx.Request.EnableBuffering();
    var body = await new StreamReader(ctx.Request.Body).ReadToEndAsync();
    return Results.Ok(new { form = ctx.Request.Form.ToDictionary(f => f.Key, f => (string)f.Value.ToString()), bodyLength = body.Length });
});"""
s = s.replace(tail, "")
s = s.replace('app.MapHealthChecks("/health");\napp.Run();',
              'app.MapHealthChecks("/health");' + tail + '\napp.Run();')
open(p, "w").write(s)
print("patched")
