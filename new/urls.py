from django.urls import path
from . import views

urlpatterns =[
    path('', views.home,name="home"),
    path('about', views.about,name="about"),
    path('documentation', views.documentation,name="documentation"),
    path('slide', views.slide,name="slide"),
    path('simulation/', views.simulation,name="simulation"),
    path('visualization', views.visualization,name="visualization"),
]