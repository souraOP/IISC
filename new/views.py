import os
import json
import logging
import mimetypes

from iisc import simulator
from iisc import validation
from iisc import (
    TASK_DIR as sample_dir,
    SAMPLE_TASK_JSON as r_json,
)
from pathlib import Path
from django.http import HttpResponse, Http404


#Authentication
from django.views import View
from .forms import RegisterForm, MyfileUploadForm
from django.contrib import messages
from django.core.mail import send_mail
from django.contrib.auth.decorators import login_required
from iisc import settings
from iisc.simulator import Simulator
from .models import file_upload
from django.contrib.auth import views as User
from django.contrib.auth.models import User
from django import forms
from django.contrib.auth import logout
from django.shortcuts import render, HttpResponse
from new.function import handle_uploaded_file


# Create your views here.


def home(request):
    return render(request, "index.html")


def about(request):
    return render(request, "about.html")


# def documentation(request):
#     return render(request, "documentation.html")


@login_required(login_url='http://127.0.0.1:8000/login/')
def simulation(request):
        return render(request, "simulation.html")


def slide(request):
    return render(request, "slide.html")


def visualization(request):
    return render(request, "visualization.html")

# def visualization(request):
#     context = {
#         'sample_dir': STATIC_DIR,
#     }
#     return render(request, "visualization_0.html", context)


@login_required(login_url='http://127.0.0.1:8000/login/')
def summary(request):
        user=request.user
        all_data = file_upload.objects.filter(uploader__id=request.user.id)
        total_files = all_data.count()
        mydict = {
            'user':user,
            'data':total_files,
            # 'submit': '10',
            # 'finish': '9',
            # 'error':'1'
            } 
        return render(request,"accountsummary.html",{'id':mydict})


def results(request):
    with open(r_json) as json_file:
        data = json.load(json_file)
        return HttpResponse(json.dumps(data), content_type='application/json')


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


@login_required(login_url='http://127.0.0.1:8000/login/')
def add_file(request):
    context={}
    if request.method == 'POST':
        form = MyfileUploadForm(request.POST, request.FILES)

        if form.is_valid():
            login_user = User.objects.get(username=request.user.username)
            name = form.cleaned_data['file_name']
            the_files = form.cleaned_data['files_data']

            file_extension = the_files.name.split(".")[-1].lower()
            if file_extension not in ['xlsx', 'json']:
                context["status"]="Invalid Task file type. Please upload an Task file (.xlsx or json)."
                return render(request, "accountsummary.html", context)
             #Check if a file with the same name already exists
            existing_file = file_upload.objects.filter(file_name=name)

            if existing_file.exists():
                context["status"] = "Task File with this name already exists"
                #form.add_error('file_name', 'File with this name already exists')
                return render(request, 'accountsummary.html', context)
            file_upload(uploader=login_user, file_name=name).save()
            context["status"] = "{}File Added Successfully"

            # FIXME:
            # ----------------------------------------------------------------------------------------------------------
            data_dir = handle_uploaded_file(file_name=the_files, task_name=name, username=request.user.username)
            input_file = os.path.join(data_dir, "input.xlsx")
            valid = validation.validate_spreadsheet(path_xlsx=Path(input_file))
            logging.info(f'valid {valid}')

            # print(valid)
            # valid=False
            # if(valid==False):
                # context["status"] = "{}Uploaded File Is Invalid"
                # return render(request,"accountsummary.html",context)
            sim = Simulator(data_path=data_dir)
            sim.runsimulation()
            sim.save_results()

            # ----------------------------------------------------------------------------------------------------------

            currentuser = request.user
            user_email = currentuser.email
            mail_message = f'The task  finished successfully.'\
                           f'You can view the results by visiting http://127.0.0.1:8000/view/'

            send_mail('Your Result is Ready', mail_message, settings.EMAIL_HOST_USER, [user_email], fail_silently=False)
            # logout(request)
            return render(request, "accountsummary.html", context)
        else:
            return HttpResponse("error")
    else:
        context = {
            'form': MyfileUploadForm()
        }
        return render(request, "upload.html", context)


@login_required(login_url='http://127.0.0.1:8000/login/')
def view(request):
    all_data = file_upload.objects.filter(uploader__id=request.user.id)
    context = {
     'data':all_data
    }
    return render(request, 'view.html', context)


@login_required(login_url='http://127.0.0.1:8000/login/')
def show_file(request, task_name):
    username = request.user.username
    task_dir = os.path.join(settings.UPLOAD_DIR, str(username), str(task_name))
    file_list = os.listdir(task_dir)
    return render(request, 'show_file.html', {'file_list': file_list, 'task_name': task_name})


def download_file(request, file_name, task_name):
    file_path = os.path.join(settings.UPLOAD_DIR, request.user.username, task_name, file_name)
    if os.path.exists(file_path):
        with open(file_path, 'rb') as fh:
            response = HttpResponse(fh.read(), content_type=mimetypes.guess_type(file_path)[0])
            response['Content-Disposition'] = 'attachment; filename=' + os.path.basename(file_path)
            return response
    raise Http404


def delete(request, file_name):
    member = file_upload.objects.get(file_name=file_name)
    member.delete()
    all_data = file_upload.objects.filter(uploader__id=request.user.id)
    context = {
        'data': all_data
    }
    return render(request, 'view.html', context)



