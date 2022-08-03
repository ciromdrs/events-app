from django.http import HttpResponse
from django.shortcuts import render

from .models import Post

def index(request):
    posts = Post.objects.all()
    print(posts, len(posts))
    return render(request, 'galleryapp/feed.html', {'posts': posts})
