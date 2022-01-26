---
layout: post
title: "Reflection"
date: 2022-01-26
place: Brno, Czech Republic
tags: oop
description: |
  ...
---

{% highlight powershell %}
.\gitlab-runner.exe register --url https://example.burmistrov.tech 
--registration-token your_registration_token
--executor shell 
--shell pwsh 
--tag-list ".NET Core, .NET Framework, MSSQL, ServerId" 
--locked=false 
--non-interactive
{% endhighlight %}