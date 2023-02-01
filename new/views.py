from django.shortcuts import render

# Create your views here.

def home(request):
    return render(request,"index.html")

def about(request):
    return render(request,"about.html")

def documentation(request):
    return render(request,"documentation.html")

def simulation(request):
        return render(request,"simulation.html")

def slide(request):
    return render(request,"slide.html")

def visualization(request):
    return render(request,"visualization.html")