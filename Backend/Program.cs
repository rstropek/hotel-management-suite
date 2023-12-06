var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.UseHttpsRedirection();
app.MapGet("/ping", () => "pong");
app.Run();
