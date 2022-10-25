import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name="Bastion",
    version="0.2",
    author="mempoule",
    author_email="mempoule@users.noreply.github.com",
    description="Bastion",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/mempoule/toolbox",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
    install_requires=[
        'pycryptodome',
        'base58'
    ]
)
