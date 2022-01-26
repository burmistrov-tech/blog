---
layout: post
title: "GitLab CI/CD"
date: 2022-01-26
place: Brno, Czech Republic
tags: oop
description: |
  ...
---
## How to set up CI/CD on your Windows Server
Prerequirments: 
- 
- Use a special system account for the runner


You can register a runner on the server using the command `gitlab-runner register`:

{% highlight powershell %}
.\gitlab-runner.exe register --url https://example.burmistrov.tech 
--registration-token your_registration_token
--executor shell 
--shell pwsh 
--tag-list ".NET Core, .NET Framework, MSSQL, ServerId" 
--locked=false 
--non-interactive
{% endhighlight %}