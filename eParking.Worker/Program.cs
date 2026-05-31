using eParking.Services;
using eParking.Services.Database;
using eParking.Worker;
using DotNetEnv;
using Microsoft.EntityFrameworkCore;

Env.TraversePath().Load();

var builder = Host.CreateApplicationBuilder(args);

builder.Services.Configure<eParking.Model.RabbitMqSettings>(builder.Configuration.GetSection("RabbitMQ"));

builder.Services.AddDbContext<ParkingDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<IUserNotificationService, UserNotificationService>();
builder.Services.AddHostedService<NotificationConsumerWorker>();

var host = builder.Build();
host.Run();
