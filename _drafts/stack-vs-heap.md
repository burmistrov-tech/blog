---
layout: post
title: "Stack vs Heap in .NET"
date: 2022-03-13
tags: oop
---

Before we start there are some terms that you probably should know. All the memory within the .NET is managing by CLR. **Common Language Runtime** is the runtime environment which controls the execution of various programming languages. Namely, the memory management, loading assemblies, security, synchronization, exceptions handling and security. Memory in .NET is presented in the form of two data structures - Stack and Heap, heap can be manageable and unmanageable. Let's dive deeper into these definitions:

The first one is the **Stack**. Each thread has its own stack, and each process can have multiple threads. When creating a thread, 1024 bytes (1 MB) are allocated to stack. The allocated memory is used for local variables, for passing parameters to methods, returning values are stored, while the application is running. The methods contain prologue code, which initializes the method before it starts working, and epilogue code, which performs cleanup after the method terminates ***execution*** and ***returns control*** to the calling method. Stack clearing occurs when the epilogue code is called from the method, which clears all the method values on the stack.

<!-- {% highlight csharp %}
{% endhighlight %} -->