#!/usr/bin/env python
try:
    from urllib.request import urlopen
except ImportError:
    from urllib import urlopen
import logging
from xml.dom import minidom


def refreshPlex(settings, source_type, logger=None):
    if logger:
        log = logger
    else:
        log = logging.getLogger(__name__)

    host = settings.Plex['host']
    port = settings.Plex['port']
    token = settings.Plex['token']

    log.debug("Host: %s." % host)
    log.debug("Port: %s." % port)
    log.debug("Token: %s." % token)

    approved_sources = ['movie', 'show']
    if settings.Plex['refresh'] and source_type in approved_sources:
        base_url = 'http://%s:%s/library/sections' % (host, port)
        refresh_url = '%s/%%s/refresh' % base_url

        if token:
            refresh_url = refresh_url + "?X-Plex-Token=" + token
            base_url = base_url + "?X-Plex-Token=" + token
            log.debug("Plex home token detected.")

        log.debug("Refresh URL: %s." % refresh_url)
        log.debug("Base URL: %s." % base_url)

        try:
            refresh(base_url, refresh_url, source_type)
        except IOError:
            try:
                import ssl
                ctx = ssl.create_default_context()
                ctx.check_hostname = False
                ctx.verify_mode = ssl.CERT_NONE
                refresh_url = refresh_url.replace("http://", "https://")
                base_url = base_url.replace("http://", "https://")
                refresh(base_url, refresh_url, source_type, ctx=ctx)
            except:
                log.error(refresh_url)
                log.error(base_url)
                log.error("Unable to refresh plex https, check your settings.")
        except Exception:
            log.exception("Unable to refresh plex, check your settings.")

def refresh(base_url, refresh_url, source_type, ctx=None):
    xml_sections = minidom.parse(urlopen(base_url, context=ctx))
    sections = xml_sections.getElementsByTagName('Directory')
    for s in sections:
        if s.getAttribute('type') == source_type:
            url = refresh_url % s.getAttribute('key')
            urlopen(url, context=ctx)