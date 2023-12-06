using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationInsightsTelemetry();
var app = builder.Build();
app.UseHttpsRedirection();

app.MapGet("/ping", () => "pong");

app.MapGet("/get-from-db", async (IConfiguration configuration) =>
{
    using var conn = new SqlConnection(configuration.GetConnectionString("Database"));
    await conn.OpenAsync();
    using var cmd = conn.CreateCommand();
    cmd.CommandText = "SELECT 42 AS [Answer]";
    return Results.Ok(await cmd.ExecuteScalarAsync());
});

app.Run();
