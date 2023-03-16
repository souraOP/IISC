from django.urls import path
from . import views

from .views import *
from django.contrib.auth import views as auth_view
from .forms import LoginForm,MyPasswordResetForm, MyPasswordChangeForm,MySetPasswordForm

urlpatterns =[
    path('', views.home,name="home"),
    path('about', views.about,name="about"),
    path('documentation', views.documentation,name="documentation"),
    path('slide', views.slide,name="slide"),
    path('simulation/', views.simulation,name="simulation"),
    path('visualization', views.visualization,name="visualization"),
    
    path('summary/', views.summary,name="summary"),
    path('upload/',views.add_file,name="add_file"),
    path('view/',views.show_file,name="view"),
    
    path('delete/<str:file_name>', views.delete, name='delete'),


    #login
    path('registration/',views.Register.as_view(),name = 'register'),
    path('login/',auth_view.LoginView.as_view(template_name='authentication/login.html',authentication_form=LoginForm) , name='login'),
    path('passwordchange/',auth_view.PasswordChangeView.as_view(template_name='authentication/changepassword.html',form_class=MyPasswordChangeForm, success_url='/passwordchangedone/'),name='passwordchange'),
    path('passwordchangedone/',auth_view.PasswordResetView.as_view(template_name='authentication/passwordchangedone.html'),name='passwordchangedone'),
    path('logout/',auth_view.LogoutView.as_view(next_page='login'),name='logout'),

    path('password-reset/',auth_view.PasswordResetView.as_view(template_name='authentication/password_reset.html',form_class=MyPasswordResetForm),name='password_reset'),
    path('password-reset/done/',auth_view.PasswordResetDoneView.as_view(template_name='authentication/password_reset_done.html'),name='password_reset_done'),
    path('password-reset-confirm/<uidb64>/<token>/',auth_view.PasswordResetConfirmView.as_view(template_name='authentication/password_reset_confirm.html',form_class=MySetPasswordForm),name='password_reset_confirm'),
    path('password-reset-complete/',auth_view.PasswordResetCompleteView.as_view(template_name='authentication/password_reset_complete.html'),name='password_reset_complete'),

]