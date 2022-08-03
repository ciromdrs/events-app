from django.db import models


class Post(models.Model):
	text = models.CharField(max_length=144)
	publication_date = models.DateTimeField()


class Like(models.Model):
	post = models.ForeignKey(Post, on_delete=models.CASCADE)