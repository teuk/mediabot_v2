#!/usr/bin/python

from apiclient.discovery import build
from apiclient.errors import HttpError
from oauth2client.tools import argparser


# Set DEVELOPER_KEY to the API key value from the APIs & auth > Registered apps
# tab of
#   https://cloud.google.com/console
# Please ensure that you have enabled the YouTube Data API for your project.
DEVELOPER_KEY = "YOU MAY USE YOUR API DEV KEY HERE"
YOUTUBE_API_SERVICE_NAME = "youtube"
YOUTUBE_API_VERSION = "v3"

def youtube_search(options):
  youtube = build(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION,
    developerKey=DEVELOPER_KEY)

  # Call the search.list method to retrieve results matching the specified
  # query term.
  search_response = youtube.videos().list(
    id=options.id,
    part="id,snippet,contentDetails,statistics",
  ).execute()

  title = []
  duration = []
  viewCount = []

  # Add each result to the appropriate list, and then display the lists of
  # matching videos, channels, and playlists.
  for search_result in search_response.get("items", []):
      title = search_result["snippet"]["title"]
      duration = search_result["contentDetails"]["duration"]
      viewCount = search_result["statistics"]["viewCount"]
      

  print "".join(title)
  print "".join(duration)
  print "".join(viewCount)

if __name__ == "__main__":
  argparser.add_argument("--id", help="Video ID", default="8gnKzPlmy2U")
  args = argparser.parse_args()

  try:
    youtube_search(args)
  except HttpError, e:
		print "An HTTP error %d occurred:\n%s" % (e.resp.status, e.content)
