# Use the official Python alpine image for 3.11 as a base image
FROM python:3.11-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the app.py and requirements.txt file into the container at /app
COPY requirements.txt /app/

# Install any dependencies specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir /app/logs
COPY app.py main.py /app/

# Expose the port that Gunicorn will run on
EXPOSE 80

# Command to run the application using Gunicorn
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:80", "app:app"]