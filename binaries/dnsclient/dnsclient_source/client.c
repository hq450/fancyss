#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h> 
#include <arpa/inet.h>
#include <sys/socket.h>

#include "dns.h"
#include "request.h"
#include "response.h"
#include "query.h"

#define DEFAULT_PORT		53
#define DEFAULT_TIMEOUT		5
#define DEFAULT_MAX_RETRIES	3

static char *get_authority_string(int is_authoritative);

static int select_ip_string(const struct dns_response *responses, int answer_count, uint16_t prefer_type,
			    char *out, size_t out_len);
static struct dns_response *resolve_once(const char *server, const char *domain, int port, int timeout, int retries,
					uint16_t q_type, int *answer_count, char *error_message);

int main(int argc, char **argv) {

  char server[MAX_DOMAIN_LENGTH + 1], domain[MAX_DOMAIN_LENGTH + 1];
  char error_message[ERROR_BUFFER + 1];
  char ip_out[INET6_ADDRSTRLEN];
  int answer_count;
  int port, timeout, retries, arg_counter, optional_argc;
  int qtype_count;
  uint16_t qtypes[2];
  struct dns_response *responses;

  *error_message = 0;

  /* Use the current time as a seed for the random number generator. */
  srand(time(0));

  /* Verify that enough arguments were passed in */
  if (argc <  3) {
    printf("USAGE: %s [-p <port>] [-t <timeout>] [-i <max-retries>] "
	   "[-4|-6|-46|-64] [-q|--ip-only] [-ns|-mx] @<server> <name>\n", argv[0]);
    exit(1);
  }

  /* set defaults for optional arguments in case none are specified */
  port		 = DEFAULT_PORT;
  timeout	 = DEFAULT_TIMEOUT;
  retries	 = DEFAULT_MAX_RETRIES;
  qtype_count    = 1;
  qtypes[0]      = DNS_A_RECORD;
  qtypes[1]      = 0;

  // counter that will be used to differntiate
  // vals from option flags
  optional_argc = argc - 2;
  arg_counter	= 1;

  // while we have enough args and the count is less
  // than the number of REQUIRED args 
  while(arg_counter < optional_argc) {
        
    // handle timeout arg
    if (strcmp("-t", argv[arg_counter]) == 0) {
      if (arg_counter + 1 < optional_argc) {
	timeout = atoi(argv[++arg_counter]);
      } else {
	fprintf(stderr, "ERROR must specify a timeout value with -t\n");
	exit(1);
      }

      // handle max retries arg
    } else if (strcmp("-i", argv[arg_counter]) == 0) {
      if (arg_counter + 1 < optional_argc) {
	retries = atoi(argv[++arg_counter]);
      } else {
	fprintf(stderr, "ERROR must specify a retry value with -i\n");
	exit(1);
      }

      // handle port arg
    } else if (strcmp("-p", argv[arg_counter]) == 0) {
      if (arg_counter + 1 < optional_argc) {
	port = atoi(argv[++arg_counter]);
      } else {
	fprintf(stderr, "ERROR must specify a port with -p\n");
	exit(1);
      }

    } else if (strcmp("-ns",argv[arg_counter]) == 0) {
      qtype_count = 1;
      qtypes[0] = DNS_NS_RECORD;

    } else if (strcmp("-mx",argv[arg_counter]) == 0) {
      qtype_count = 1;
      qtypes[0] = DNS_MX_RECORD;

    } else if (strcmp("-q", argv[arg_counter]) == 0 ||
	       strcmp("--ip-only", argv[arg_counter]) == 0) {
      /* kept for backward compatibility; this fork always prints pure IP only */

    } else if (strcmp("-4", argv[arg_counter]) == 0) {
      qtype_count = 1;
      qtypes[0] = DNS_A_RECORD;

    } else if (strcmp("-6", argv[arg_counter]) == 0) {
      qtype_count = 1;
      qtypes[0] = DNS_AAAA_RECORD;

    } else if (strcmp("-46", argv[arg_counter]) == 0) {
      qtype_count = 2;
      qtypes[0] = DNS_A_RECORD;
      qtypes[1] = DNS_AAAA_RECORD;

    } else if (strcmp("-64", argv[arg_counter]) == 0) {
      qtype_count = 2;
      qtypes[0] = DNS_AAAA_RECORD;
      qtypes[1] = DNS_A_RECORD;
    }

    ++arg_counter;
  }

  if (strlen(argv[argc - 2]) > MAX_DOMAIN_LENGTH ||
      strlen(argv[argc - 1]) > MAX_DOMAIN_LENGTH) {
    fprintf(stderr, "ERROR max length of server and domain is %d\n", 
	    MAX_DOMAIN_LENGTH);
    exit(1);
  }

  /* Use arg list to set REQUIRED variables. If the server name starts with an
     @, don't include it when copying into the buffer. */
  if (*argv[argc - 2] == '@') {
    strncpy(server, argv[argc - 2] + 1, MAX_DOMAIN_LENGTH);
  } else {
    strncpy(server, argv[argc - 2], MAX_DOMAIN_LENGTH);
  }
  strncpy(domain, argv[argc - 1], MAX_DOMAIN_LENGTH);

  /* Resolve according to qtype strategy. */
  if (qtype_count == 1) {
    responses = resolve_once(server, domain, port, timeout, retries, qtypes[0], &answer_count, error_message);
    if (responses == 0) {
      if (*error_message != 0)
	fprintf(stderr, "ERROR %s\n", error_message);
      return 1;
    }

    if (select_ip_string(responses, answer_count, qtypes[0], ip_out, sizeof(ip_out))) {
      fprintf(stdout, "%s\n", ip_out);
      free(responses);
      return 0;
    }

    free(responses);
    return 1;
  }

  /* Prefer mode: try first qtype; if no matching A/AAAA exists, fallback to second. */
  responses = resolve_once(server, domain, port, timeout, retries, qtypes[0], &answer_count, error_message);
  if (responses != 0 && select_ip_string(responses, answer_count, qtypes[0], ip_out, sizeof(ip_out))) {
    fprintf(stdout, "%s\n", ip_out);
    free(responses);
    return 0;
  }
  if (responses != 0) {
    free(responses);
    responses = 0;
  }

  *error_message = 0;
  responses = resolve_once(server, domain, port, timeout, retries, qtypes[1], &answer_count, error_message);
  if (responses == 0) {
    if (*error_message != 0)
      fprintf(stderr, "ERROR %s\n", error_message);
    return 1;
  }

  if (select_ip_string(responses, answer_count, qtypes[1], ip_out, sizeof(ip_out))) {
    fprintf(stdout, "%s\n", ip_out);
    free(responses);
    return 0;
  }
  free(responses);
  return 1;
}

static char *get_authority_string(int is_authoritative) {
  return is_authoritative ? "auth" : "nonauth";
}

static int select_ip_string(const struct dns_response *responses, int answer_count, uint16_t prefer_type,
			    char *out, size_t out_len) {
  int i;
  for (i = 0; i < answer_count; ++i) {
    if (responses[i].response_type != prefer_type)
      continue;

    if (prefer_type == DNS_A_RECORD) {
      struct in_addr a4;
      a4.s_addr = htonl(responses[i].ip_address);
      return inet_ntop(AF_INET, &a4, out, out_len) != 0;
    }
    if (prefer_type == DNS_AAAA_RECORD) {
      return inet_ntop(AF_INET6, responses[i].ip6_address, out, out_len) != 0;
    }
  }
  (void)get_authority_string; /* keep the legacy helper referenced */
  return 0;
}

static struct dns_response *resolve_once(const char *server, const char *domain, int port, int timeout, int retries,
					uint16_t q_type, int *answer_count, char *error_message) {
  int request_id, packet_size;
  void *request_buffer, *response_buffer;
  struct dns_response *responses;

  *error_message = 0;

  request_buffer = build_dns_request_packet(domain, &packet_size, &request_id, q_type, error_message);
  if (request_buffer == 0) {
    return 0;
  }

  response_buffer = query_dns_server(request_buffer, &packet_size, server, port, timeout, retries, error_message);
  free_dns_request_packet(request_buffer);
  if (response_buffer == 0) {
    return 0;
  }

  responses = parse_dns_response(response_buffer, packet_size, request_id, domain, answer_count, error_message);
  free_response_buffer(response_buffer);
  return responses; /* may be NULL on NOTFOUND (with empty error_message). */
}
