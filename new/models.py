from django.db import models
from django.contrib.auth.models import User

# Create your models here.
class file_upload(models.Model):
    uploader=models.ForeignKey(User,on_delete=models.CASCADE)
    ids = models.AutoField(primary_key=True)
    file_name = models.CharField(max_length=255)
    # my_file = models.FileField(upload_to='')
    added_on = models.DateTimeField(auto_now_add=True,null=True)

    def __str__(self):
        return self.file_name

# class SimulationResult(models.Model):
#     name = models.CharField(max_length=255)
#     username = models.ForeignKey(User, on_delete=models.CASCADE)
#     url = models.URLField()
