FROM mcr.microsoft.com/azure-powershell AS base

WORKDIR /

COPY Update-DNSRecord-ACI.ps1 .

# Creates a non-root user with an explicit UID
#RUN adduser -u 5678 --disabled-password --gecos "" appuser

# Assign the new user as the owner of the app folder
#RUN chown -R appuser /app 

#USER appuser

#CMD [ "./Update-DNSRecord-ACI.ps1" ]

ENTRYPOINT ["pwsh", "/run.ps1"]