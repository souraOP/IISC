from django.shortcuts import render


#Authonication
from django.views import View
from .forms import RegisterForm
from django.contrib import messages
from django.core.mail import send_mail
from django.contrib.auth.decorators import login_required
from iisc import settings

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

@login_required(login_url='http://127.0.0.1:8000/login/')
def summary(request):
        mydict = {
            'submit': '10',
            'finish': '9',
            'error':'1'
            }
        return render(request,"accountsummary.html",{'id':mydict})

class Register(View):
    def get(self,request):
        form = RegisterForm()
        return render(request,'authentication/Register.html',locals())
    def post(self,request):
        form = RegisterForm(request.POST)
        user_email= request.POST['email']
        user_username= request.POST['username']
        user_password1= request.POST['password1']
        if form.is_valid():
            form.save()
            mail_message=f'Your account Register successfully your Username is- {user_username} And Password is- {user_password1}'
            send_mail('Register account successfull',mail_message,settings.EMAIL_HOST_USER,[user_email],fail_silently=False)
            messages.success(request,"Congratulations! User Register Successfully")
        else:
            messages.warning(request,"Invalid Input Data")  
        return render(request,'authentication/Register.html',locals()) 
