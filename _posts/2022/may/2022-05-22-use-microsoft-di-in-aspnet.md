---
layout: post
title: "Use Microsoft Dependency Injection in your ASP.NET Web project"
date: 2022-05-22
tags: |
  csharp
  aspnet
---

If you have been "lucky" enough to work with ASP.NET Web project, then most likely you have had experience with different dependency injection libraries. For a long time Unity, Autofac, Ninject and others have successfully covered dependency injection needs, each of them support ASP.NET Web and provide their own IoC containers that have quite comfortable API to work with (except Unity, it is terrible), but there is still one little problem.

The arrival of ASP.NET Core, and with it `Microsoft.Extensions.DependencyInjection` set a new standard in dependency injection. Every modern solutions now focus on Microsoft DI and provide their own extension methods to work with it. For example, if you want to use [Serilog](https://github.com/serilog/serilog-extensions-logging) in your solution, you can achieve this with a few lines of code.

```csharp
var container = new ServiceCollection();

container.AddLogging(builder => builder.AddSerilog(logger));
```

But unfortunately, Microsoft DI doesn't implement `IDependencyResolver` out of the box, which is the interface ASP.NET Web uses to resolve dependencies. Below, I'll show you how to implement this interface yourself, but first let's take a look at it.

## Under the hood

```csharp

namespace System.Web.Http.Dependencies
{
  /// <summary>Represents a dependency injection container.</summary>
  public interface IDependencyResolver : IDependencyScope, IDisposable
  {
    /// <summary> Starts a resolution scope. </summary>
    /// <returns>The dependency scope.</returns>
    IDependencyScope BeginScope();
  }

  /// <summary>Represents an interface for the range of the dependencies.</summary>
  public interface IDependencyScope : IDisposable
  {
    /// <summary>Retrieves a service from the scope.</summary>
    /// <returns>The retrieved service.</returns>
    /// <param name="serviceType">The service to be retrieved.</param>
    object GetService(Type serviceType);

    /// <summary>Retrieves a collection of services from the scope.</summary>
    /// <returns>The retrieved collection of services.</returns>
    /// <param name="serviceType">The collection of services to be retrieved.</param>
    IEnumerable<object> GetServices(Type serviceType);
  }
}
```

If we compare IServiceProvider and IDependencyResolver, they are generally similar. Except that IServiceProvider contains generic overloaded methods and asynchronous scoping. Therefore, all we need is to make them compatible to convert one interface to the other.

## Adapting IServiceProvider to IDependencyResolver

```csharp
public class DependencyInjectionResolver : IDependencyResolver, IServiceProvider, IAsyncDisposable
{
  private readonly IServiceProvider _serviceProvider;
  private bool _disposed;

  public DependencyInjectionResolver(IServiceProvider serviceProvider)
  {
    _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
  }

  public IDependencyScope BeginScope()
  {
    var scope = _serviceProvider.CreateScope();

    return new DependencyInjectionResolver(scope.ServiceProvider);
  }

  public object GetService(Type serviceType)
  {
    if (serviceType == null) throw new ArgumentNullException(nameof(serviceType));
    
    return _serviceProvider.GetService(serviceType);
  }

  public IEnumerable<object> GetServices(Type serviceType)
  {
    if (serviceType == null) throw new ArgumentNullException(nameof(serviceType));
    
    return _serviceProvider.GetServices(serviceType);
  }

  public void Dispose()
  {
    if (_disposed || !(_serviceProvider is IDisposable disposable)) return;
    
    _disposed = true;
    disposable.Dispose();
  }

  public ValueTask DisposeAsync()
  {
    if (_disposed) return default;
    
    if (_serviceProvider is IAsyncDisposable asyncDisposable)
    {
        _disposed = true;
        return asyncDisposable.DisposeAsync();
    }
    
    Dispose();
    
    return default;
  }
}
```

```csharp
public static class ServiceCollectionExtensions
{
  public static IServiceCollection AddControllers(this IServiceCollection services)
  {
    if (services == null) throw new ArgumentNullException(nameof(services));

    var controllers = Assembly.GetExecutingAssembly().ExportedTypes
      .Where(t => !t.IsAbstract && !t.IsGenericTypeDefinition)
      .Where(t => typeof(IHttpController).IsAssignableFrom(t)
            || t.Name.EndsWith("Controller", StringComparison.OrdinalIgnoreCase));

    foreach (var controller in controllers)
    {
        services.AddTransient(controller);
    }

    return services;
  }

  public static DependencyInjectionResolver ToDependencyResolver(this IServiceCollection services)
  {
    if (services == null) throw new ArgumentNullException(nameof(services));
    
    var serviceProvider = services.BuildServiceProvider();
    
    return new DependencyInjectionResolver(serviceProvider);
  }
}
```

## How to use the adapter

```csharp
public static class HttpConfigurationExtensions
{
  public static void AddDependencyInjection(this HttpConfiguration httpConfiguration)
  {
    var container = new ServiceCollection();

    container
      // in the Web Api, it's necessary to register controllers in the DependencyResolver
      .AddWebApiControllers()
      .AddSingleton<IServiceOne, ServiceOne>()
      .AddSingleton<IServiceTwo, ServiceTwo>();

    httpConfiguration.DependencyResolver = container.ToDependencyResolver();
  }
}

public class WebApiApplication : HttpApplication
{
  protected void Application_Start()
  {
    GlobalConfiguration.Configure(configuration =>
    {
      // calling our extension method
      configuration.AddDependencyInjection();
    });
  }
}
```
The above source code can also be found in [this](https://github.com/burmistrov-tech/extensions-dependencyresolver) repository on GitHub, feel free to open a pull request if something has been missed.