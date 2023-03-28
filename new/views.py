import os
import json
import logging
import mimetypes
import shutil
import configparser

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
from django.shortcuts import render, HttpResponse,redirect
from new.function import handle_uploaded_file
from django.contrib import messages

# Create your views here.


def home(request):
    return render(request, "index.html")


def about(request):
    return render(request, "about.html")


@login_required(login_url='http://127.0.0.1:8000/login/')
def simulation(request):
        return render(request, "simulation.html")


def slide(request):
    return render(request, "slide.html")


def visualization(request):
    return render(request, "visualization.html")


@login_required(login_url='http://127.0.0.1:8000/login/')
def summary(request):
        user=request.user
        all_data = file_upload.objects.filter(uploader__id=request.user.id)
        total_files = all_data.count()
        # mydict = {
        #     'user':user,
        #     'data':total_files,
        #     } 
        # return render(request,"accountsummary.html",{'id':mydict})
        return render(request,"accountsummary.html",locals())


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
            user=request.user
            all_data = file_upload.objects.filter(uploader__id=request.user.id)
            total_files = all_data.count()
            # mydict = {
            #     'user':user,
            #     'data':total_files,
            # }

            file_extension = the_files.name.split(".")[-1].lower()
            if file_extension not in ['xlsx', 'json']:
                messages.warning(request,"Invalid Task file type. Please upload an Task file (.xlsx or json).")
                return render(request,"accountsummary.html",locals())
                # context["status"]="Invalid Task file type. Please upload an Task file (.xlsx or json)."
                # return render(request,'accountsummary.html',{'id':mydict,**context})
             #Check if a file with the same name already exists
            existing_file = file_upload.objects.filter(file_name=name)

            if existing_file.exists():
                messages.warning(request,"Task File with this name already exists")
                return render(request,"accountsummary.html",locals())
                # context["status"] = "Task File with this name already exists"
                # return render(request, 'accountsummary.html',{'id':mydict,**context})
            file_upload(uploader=login_user, file_name=name).save()
            messages.success(request,"Congratulation! File Added Successfully")
            # context["status"] = "{}File Added Successfully"

            # FIXME:
            # ----------------------------------------------------------------------------------------------------------
            data_dir = handle_uploaded_file(file_name=the_files, task_name=name, username=request.user.username)
            input_file = os.path.join(data_dir, "input.xlsx")
            valid = validation.validate_spreadsheet(path_xlsx=Path(input_file))
            logging.info(f'valid {valid}')

            print(valid)
            # valid=False
            # if(valid==False):
            #     context["status"] = "{}Uploaded File Is Invalid"
            #     return render(request,"accountsummary.html",context)
            sim = Simulator(data_path=data_dir)
            sim.runsimulation()
            sim.save_results()

            # ----------------------------------------------------------------------------------------------------------

            currentuser = request.user
            user_email = currentuser.email
            mail_message = f'The task  finished successfully.'\
                           f'You can view the results by visiting http://127.0.0.1:8000/view/'

           # send_mail('Your Result is Ready', mail_message, settings.EMAIL_HOST_USER, [user_email], fail_silently=False)
            # return redirect("summary")
            user=request.user
            all_data = file_upload.objects.filter(uploader__id=request.user.id)
            total_files = all_data.count()
            # mydict = {
            #     'user':user,
            #     'data':total_files,
            # }
            # return render(request, 'accountsummary.html',{'id':mydict,**context})
            return render(request,"accountsummary.html",locals())
            
        else:
            return HttpResponse("error")
    else:
        context = {
            'form': MyfileUploadForm()
        }
        
        return render(request, "upload.html", context)


@login_required(login_url='http://127.0.0.1:8000/login/')
def input_form(request):

    username = request.user.username
    fpath = os.path.join(settings.UPLOAD_DIR, str(username), 'input.ini')

    if request.method == 'POST':

        config = configparser.ConfigParser()
        config['UserData'] = {
            'input1': request.POST.get('input1'),
            'input2': request.POST.get('input2'),
            'input3': request.POST.get('input3'),
            'input4': request.POST.get('input4'),
        }
        with open(fpath, 'w') as configfile:
            config.write(configfile)
        return redirect('view')
        # return render(request, 'input_form.html')

    else:
        return HttpResponse("error")


@login_required(login_url='http://127.0.0.1:8000/login/')
def view(request):
    all_data = file_upload.objects.filter(uploader__id=request.user.id)
    logging.info(all_data)
    context = {
     'data': all_data
    }
    logging.info(context)
    return render(request, 'view.html', context)


# @login_required(login_url='http://127.0.0.1:8000/login/')
# def show_file(request, task_name):
#     username = request.user.username
#     task_dir = os.path.join(settings.UPLOAD_DIR, str(username), str(task_name))
#     file_list = os.listdir(task_dir)
#     logging.info(f'show: {file_list}')
#     return render(request, 'show_file.html', {'file_list': file_list, 'task_name': task_name})


# def download_file(request, file_name, task_name):
#     file_path = os.path.join(settings.UPLOAD_DIR, request.user.username, task_name, file_name)
#     if os.path.exists(file_path):
#         with open(file_path, 'rb') as fh:
#             response = HttpResponse(fh.read(), content_type=mimetypes.guess_type(file_path)[0])
#             response['Content-Disposition'] = 'attachment; filename=' + os.path.basename(file_path)
#             return response
#     raise Http404


@login_required(login_url='http://127.0.0.1:8000/login/')
def show_file(request, task_name):
    fpath = os.path.join(settings.UPLOAD_DIR, request.user.username, task_name, 'results.zip')
    if os.path.exists(fpath):
        return render(request, 'show_file.html', {'file_list': ['results.zip'], 'task_name': task_name})
    raise Http404


def download_file(request,task_name):

    fpath = os.path.join(settings.UPLOAD_DIR, request.user.username, task_name, 'results.zip')
    if os.path.exists(fpath):
        # open the zip file in binary mode
        with open(fpath, 'rb') as f:
            # create a new HTTP response object
            response = HttpResponse(f.read(), content_type='application/zip')
            # set the content-disposition header to force a download
            response['Content-Disposition'] = 'attachment; filename="%s"' % os.path.basename(fpath)
            return response
    raise Http404


def delete(request, file_name):
    logging.info(f'delete {file_name}')
    # remove from results table
    member = file_upload.objects.get(file_name=file_name)
    member.delete()
    all_data = file_upload.objects.filter(uploader__id=request.user.id)
    context = {
        'data': all_data
    }
    # remove folder from upload
    username = request.user.username
    task_dir = os.path.join(settings.UPLOAD_DIR, str(username), str(file_name))
    shutil.rmtree(task_dir)
    # return render(request, 'view.html', context)
    return redirect('view')


