using eParking.Services.Messaging;
using eParking.Model;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace eParking.Services
{
    public static class MessagingServiceCollectionExtensions
    {
        public static IServiceCollection AddEParkingMessaging(this IServiceCollection services, IConfiguration configuration)
        {
            services.Configure<RabbitMqSettings>(configuration.GetSection("RabbitMQ"));

            var enabled = configuration.GetValue("RabbitMQ:Enabled", false);
            if (enabled)
                services.AddSingleton<INotificationQueuePublisher, RabbitMqNotificationPublisher>();
            else
                services.AddSingleton<INotificationQueuePublisher, DirectNotificationQueuePublisher>();

            return services;
        }
    }
}
